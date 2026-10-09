--- The game: a world, a free-flying camera, the renderer and the player's input,
--- plus the rules for breaking and placing blocks.

local Blocks = require("src.world.blocks")
local Camera = require("src.render.camera")
local Config = require("src.config")
local Crosshair = require("src.render.crosshair")
local Input = require("src.input")
local Raycast = require("src.world.raycast")
local Renderer = require("src.render.renderer")
local Vec3 = require("src.math.vec3")
local WorldLoader = require("src.world.load")

--- @class Game
--- @field world World
--- @field camera Camera
--- @field renderer Renderer
--- @field input MouseKeyboard|TouchInput The session's one input (see src/input/).
local Game = {}
Game.__index = Game

--- Places the camera outside one corner of the world, looking at its center.
--- @param world World
--- @return Camera
local function spawnCamera(world)
    local size = world.size
    local position = Vec3.new(-0.1 * size.x, -0.1 * size.y, size.z + 6)
    return Camera.new({
        position = position,
        yaw = math.atan2(size.y / 2 - position.y, size.x / 2 - position.x),
        pitch = math.rad(-25),
        fov = Config.fov, near = Config.nearPlane, far = Config.farPlane,
    })
end

--- Loads the world and sets up the input. Errors if the world can't be loaded.
--- @param worldPath string A .vox file.
--- @param touchMode boolean On-screen touch controls instead of mouse & keyboard.
--- @return Game
function Game.new(worldPath, touchMode)
    local world = WorldLoader.load(worldPath)
    return setmetatable({
        world = world,
        camera = spawnCamera(world),
        renderer = Renderer.new(world, { chunkSize = Config.chunkSize, textureDir = Config.textureDir }),
        input = Input.use(touchMode),
    }, Game)
end

--- @param block Vec3
--- @param id BlockId
function Game:setBlock(block, id)
    if self.world:set(block, id) then
        self.renderer:blockChanged(block)
    end
end

--- Breaks or places a block at the crosshair.
--- @param action BlockAction
function Game:interact(action)
    local world, camera = self.world, self.camera
    local hit = Raycast.cast(function(block) return world:isSolid(block) end,
        camera.position, camera:forward(), Config.reach)
    if not hit then
        return
    end

    if action == "break" then
        self:setBlock(hit.block, Blocks.AIR)
    elseif action == "place" then
        if hit.normal == Vec3.ZERO then
            return -- camera is inside a block; there is no face to build on
        end
        local target = hit.block + hit.normal
        if target ~= camera.position:floor() then
            self:setBlock(target, Blocks.DIRT)
        end
    end
end

--- Applies this frame's input and rebuilds changed chunks.
--- @param dt number Seconds since the last frame.
function Game:update(dt)
    local frame = self.input:takeFrame()
    self.camera:rotate(frame.yaw, frame.pitch)
    local speed = Config.moveSpeed * (frame.fast and Config.fastMultiplier or 1)
    self.camera:move(dt, frame.forward, frame.right, frame.up, speed)
    for _, action in ipairs(frame.actions) do
        self:interact(action)
    end
    self.renderer:update()
end

function Game:draw()
    local width, height = love.graphics.getDimensions()
    self.renderer:draw(self.camera:viewProjection(width / height))
    Crosshair.draw()
    self.input:draw()
end

return Game
