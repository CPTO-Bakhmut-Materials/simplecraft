--- Entry point: loads the world and wires camera, renderer, input and HUD together.
-- Usage: `love . [path/to/world.vox] [--touch]`
-- `--touch` starts with the on-screen touch controls (the web page passes it on
-- touch-first devices; Android and iOS always start with them). See src/input.lua.

local Blocks = require("src.blocks")
local Camera = require("src.camera")
local Config = require("src.config")
local Hud = require("src.hud")
local Input = require("src.input")
local Raycast = require("src.raycast")
local Renderer = require("src.renderer")
local Vec3 = require("src.math.vec3")
local Vox = require("src.vox")
local World = require("src.world")

local world --- @type World
local camera --- @type Camera
local renderer --- @type Renderer
local input --- @type Input
local hud = Hud.new()

--- Reads a file from the game directory, falling back to the OS filesystem
-- so worlds outside the project can be passed on the command line.
local function readFile(path)
    if love.filesystem.getInfo(path, "file") then
        return assert(love.filesystem.read(path))
    end
    local file, err = io.open(path, "rb")
    if not file then
        error(("cannot open world file: %s"):format(err), 0)
    end
    local data = file:read("*a")
    file:close()
    return data
end

local function loadWorld(path)
    local ok, result = pcall(function()
        local vox = Vox.parse(readFile(path))
        if #vox.models > 1 then
            print(("warning: '%s' has %d models; only the first is loaded"):format(path, #vox.models))
        end
        return World.fromVox(vox)
    end)
    if not ok then
        error(("Failed to load world '%s':\n%s"):format(path, result), 0)
    end
    return result
end

--- Places the camera outside one corner of the world, looking at its center.
local function spawnCamera()
    local size = world.size
    local position = Vec3.new(-0.1 * size.x, -0.1 * size.y, size.z + 6)
    return Camera.new({
        position = position,
        yaw = math.atan2(size.y / 2 - position.y, size.x / 2 - position.x),
        pitch = math.rad(-25),
        fov = Config.fov, near = Config.nearPlane, far = Config.farPlane,
    })
end

local function isSolid(x, y, z)
    return world:isSolid(x, y, z)
end

--- @param block Vec3
--- @param id BlockId
local function setBlock(block, id)
    if world:set(block.x, block.y, block.z, id) then
        renderer:blockChanged(block)
    end
end

--- Breaks or places a block at the crosshair.
--- @param action BlockAction
local function interact(action)
    local hit = Raycast.cast(isSolid, camera.position, camera:forward(), Config.reach)
    if not hit then
        return
    end

    if action == "break" then
        setBlock(hit.block, Blocks.AIR)
    elseif action == "place" then
        if hit.normal == Vec3.new(0, 0, 0) then
            return -- camera is inside a block; there is no face to build on
        end
        local target = hit.block + hit.normal
        if target ~= camera.position:floor() then
            setBlock(target, Blocks.DIRT)
        end
    end
end

--- @param args string[] Command-line arguments after the game path.
--- @return string worldPath
--- @return boolean touch
local function parseArgs(args)
    local worldPath, touch = Config.worldPath, false
    for _, value in ipairs(args) do
        if value == "--touch" then
            touch = true
        elseif value:sub(1, 2) == "--" then
            error(("unknown option '%s'\nUsage: love . [path/to/world.vox] [--touch]"):format(value), 0)
        else
            worldPath = value
        end
    end
    return worldPath, touch
end

function love.load(args)
    local worldPath, touch = parseArgs(args)
    local system = love.system.getOS()

    world = loadWorld(worldPath)
    camera = spawnCamera()
    renderer = Renderer.new(world, { chunkSize = Config.chunkSize, textureDir = Config.textureDir })
    hud:resize(love.graphics.getDimensions())
    input = Input.new(hud, touch or system == "Android" or system == "iOS")
    love.graphics.setBackgroundColor(Config.skyColor)
end

function love.update(dt)
    -- Checked every frame: love.resize misses some size changes, such as a window
    -- manager resizing the window as it opens.
    hud:resize(love.graphics.getDimensions())
    local frame = input:takeFrame()
    camera:rotate(frame.yaw, frame.pitch)
    local speed = Config.moveSpeed * (frame.fast and Config.fastMultiplier or 1)
    camera:move(dt, frame.forward, frame.right, frame.up, speed)
    for _, action in ipairs(frame.actions) do
        interact(action)
    end
    renderer:update()
end

function love.draw()
    renderer:draw(camera:viewProjection(love.graphics.getWidth() / love.graphics.getHeight()))
    hud:draw(input.touchMode, input.touch)
end

function love.keypressed(key)
    input:keypressed(key)
    -- In a browser, Esc already releases the mouse and quitting would just freeze the page.
    if key == Config.keys.quit and love.system.getOS() ~= "Web" then
        love.event.quit()
    end
end

function love.touchpressed(id, x, y) input:touchpressed(id, x, y) end
function love.touchmoved(id, x, y, dx, dy) input:touchmoved(id, x, y, dx, dy) end
function love.touchreleased(id) input:touchreleased(id) end
function love.mousemoved(x, y, dx, dy, istouch) input:mousemoved(x, y, dx, dy, istouch) end
function love.mousepressed(x, y, button, istouch) input:mousepressed(x, y, button, istouch) end
function love.mousereleased(_, _, button, istouch) input:mousereleased(button, istouch) end
function love.focus(focused) input:focus(focused) end
