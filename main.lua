--- Entry point: wires world, camera, renderer and input together.
-- Usage: `love .` or `love . path/to/world.vox`

local Blocks = require("src.blocks")
local Camera = require("src.camera")
local Config = require("src.config")
local Raycast = require("src.raycast")
local Renderer = require("src.renderer")
local Vox = require("src.vox")
local World = require("src.world")

local world --- @type World
local camera --- @type Camera
local renderer --- @type Renderer

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
    local x, y, z = -0.1 * world.sizeX, -0.1 * world.sizeY, world.sizeZ + 6
    return Camera.new({
        x = x, y = y, z = z,
        yaw = math.atan2(world.sizeY / 2 - y, world.sizeX / 2 - x),
        pitch = math.rad(-25),
        fov = Config.fov, near = Config.nearPlane, far = Config.farPlane,
    })
end

local function isSolid(x, y, z)
    return world:isSolid(x, y, z)
end

local function axis(positiveKey, negativeKey)
    local value = 0
    if love.keyboard.isDown(positiveKey) then value = value + 1 end
    if love.keyboard.isDown(negativeKey) then value = value - 1 end
    return value
end

local function setBlock(x, y, z, id)
    if world:set(x, y, z, id) then
        renderer:blockChanged(x, y, z)
    end
end

local function interact(button)
    local fx, fy, fz = camera:forward()
    local hit = Raycast.cast(isSolid, camera.x, camera.y, camera.z, fx, fy, fz, Config.reach)
    if not hit then
        return
    end

    if button == Config.mouseButtons.breakBlock then
        setBlock(hit.x, hit.y, hit.z, Blocks.AIR)
    elseif button == Config.mouseButtons.placeBlock then
        if hit.nx == 0 and hit.ny == 0 and hit.nz == 0 then
            return -- camera is inside a block; there is no face to build on
        end
        local x, y, z = hit.x + hit.nx, hit.y + hit.ny, hit.z + hit.nz
        local insideCamera = x == math.floor(camera.x) and y == math.floor(camera.y) and z == math.floor(camera.z)
        if not insideCamera then
            setBlock(x, y, z, Blocks.DIRT)
        end
    end
end

local function drawCrosshair()
    local cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    love.graphics.setLineWidth(2)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.line(cx - 8, cy, cx + 8, cy)
    love.graphics.line(cx, cy - 8, cx, cy + 8)
    love.graphics.setColor(1, 1, 1, 1)
end

function love.load(args)
    world = loadWorld(args[1] or Config.worldPath)
    camera = spawnCamera()
    renderer = Renderer.new(world, { chunkSize = Config.chunkSize, textureDir = Config.textureDir })
    love.graphics.setBackgroundColor(Config.skyColor)
    love.mouse.setRelativeMode(true)
end

function love.update(dt)
    local keys = Config.keys
    local speed = Config.moveSpeed * (love.keyboard.isDown(keys.fast) and Config.fastMultiplier or 1)
    camera:move(dt, axis(keys.forward, keys.back), axis(keys.right, keys.left), axis(keys.up, keys.down), speed)
    renderer:update()
end

function love.draw()
    renderer:draw(camera:viewProjection(love.graphics.getWidth() / love.graphics.getHeight()))
    drawCrosshair()
end

function love.mousemoved(_, _, dx, dy)
    if love.mouse.getRelativeMode() then
        local sensitivity = Config.mouseSensitivity
        camera:rotate(-dx * sensitivity, -dy * sensitivity)
    end
end

function love.mousepressed(_, _, button)
    if not love.mouse.getRelativeMode() then
        love.mouse.setRelativeMode(true) -- first click after refocusing only recaptures the mouse
        return
    end
    interact(button)
end

function love.keypressed(key)
    -- In a browser, Esc already releases the mouse and quitting would just freeze the page.
    if key == Config.keys.quit and love.system.getOS() ~= "Web" then
        love.event.quit()
    end
end

function love.focus(focused)
    if not focused then
        love.mouse.setRelativeMode(false)
    end
end
