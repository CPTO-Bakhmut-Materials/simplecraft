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

--- A change to one block, decided by Game.chooseEdit.
--- @class BlockEdit
--- @field block Vec3
--- @field id BlockId What the block becomes.

--- @class Game
--- @field world World
--- @field camera Camera
--- @field renderer Renderer
--- @field input MouseKeyboardInput|TouchInput The session's one input (see src/input/).
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

--- The rules for breaking and placing: which block an action at the crosshair
--- changes, and to what. Breaking clears the block the crosshair points at;
--- placing puts dirt against the face it points at, unless that is where the
--- camera is. Returns nil when the action does nothing.
--- @param world World
--- @param camera Camera
--- @param action BlockAction
--- @return BlockEdit?
function Game.chooseEdit(world, camera, action)
    local hit = Raycast.cast(function(block) return world:isSolid(block) end,
        camera.position, camera:forward(), Config.reach)
    if not hit then
        return nil
    end
    if action == "break" then
        return { block = hit.block, id = Blocks.AIR }
    end
    if hit.normal == Vec3.ZERO then
        return nil -- the camera is inside a block; there is no face to build on
    end
    local target = hit.block + hit.normal
    if target == camera.position:floor() then
        return nil -- don't build a block around the camera
    end
    return { block = target, id = Blocks.DIRT }
end

--- Breaks or places a block at the crosshair.
--- @param action BlockAction
function Game:interact(action)
    local edit = Game.chooseEdit(self.world, self.camera, action)
    if edit and self.world:set(edit.block, edit.id) then
        self.renderer:blockChanged(edit.block)
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
