--- Entry point: wires world, camera, renderer and input together.
-- Usage: `love . [path/to/world.vox] [--touch]`
--
-- Input is either mouse/keyboard or touch, never chosen on the fly: the game
-- starts in touch mode on Android/iOS or with `--touch` (the web page passes it
-- on touch-first devices), and only the toggle button in the top-right corner
-- (or the toggle key) switches. In touch mode the left mouse button acts as a
-- finger; in mouse mode touches only reach the toggle button.

local Blocks = require("src.blocks")
local Camera = require("src.camera")
local Config = require("src.config")
local Raycast = require("src.raycast")
local Renderer = require("src.renderer")
local InputToggle = require("src.input_toggle")
local TouchControls = require("src.touch_controls")
local Vec3 = require("src.math.vec3")
local Vox = require("src.vox")
local World = require("src.world")

local world --- @type World
local camera --- @type Camera
local renderer --- @type Renderer
local touch = TouchControls.new()
local inputToggle = InputToggle.new()
local touchMode = false -- on-screen controls shown and the mouse left uncaptured

local MOUSE_TOUCH_ID = "mouse" -- touch id for the mouse acting as a finger

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

local function axis(positiveKey, negativeKey)
    local value = 0
    if love.keyboard.isDown(positiveKey) then value = value + 1 end
    if love.keyboard.isDown(negativeKey) then value = value - 1 end
    return value
end

--- @param block Vec3
--- @param id BlockId
local function setBlock(block, id)
    if world:set(block.x, block.y, block.z, id) then
        renderer:blockChanged(block)
    end
end

--- Breaks or places a block at the crosshair.
--- @param action TouchAction
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

local function drawCrosshair()
    local cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    love.graphics.setLineWidth(2)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.line(cx - 8, cy, cx + 8, cy)
    love.graphics.line(cx, cy - 8, cx, cy + 8)
    love.graphics.setColor(1, 1, 1, 1)
end

--- Fits the on-screen UI to the current window size; cheap when unchanged.
local function layoutUi()
    local width, height = love.graphics.getDimensions()
    touch:resize(width, height)
    inputToggle:resize(width, height)
end

--- Switches between touch controls and mouse/keyboard controls. The mouse is
--- left uncaptured either way: in mouse mode the next click captures it.
--- @param enabled boolean
local function setTouchMode(enabled)
    touchMode = enabled
    touch:reset()
    love.mouse.setRelativeMode(false)
end

function love.load(args)
    local worldPath = Config.worldPath
    for _, value in ipairs(args) do
        if value == "--touch" then
            touchMode = true
        else
            worldPath = value
        end
    end
    local system = love.system.getOS()
    touchMode = touchMode or system == "Android" or system == "iOS"

    world = loadWorld(worldPath)
    camera = spawnCamera()
    renderer = Renderer.new(world, { chunkSize = Config.chunkSize, textureDir = Config.textureDir })
    love.graphics.setBackgroundColor(Config.skyColor)
    love.mouse.setRelativeMode(not touchMode)
end

function love.update(dt)
    layoutUi()
    local keys = Config.keys
    local speed = Config.moveSpeed * (love.keyboard.isDown(keys.fast) and Config.fastMultiplier or 1)
    local forward, right, up = axis(keys.forward, keys.back), axis(keys.right, keys.left), axis(keys.up, keys.down)
    if touchMode then
        local touchForward, touchRight, touchUp = touch:movement()
        forward, right, up = forward + touchForward, right + touchRight, up + touchUp
        local lookX, lookY = touch:takeLook()
        camera:rotate(-lookX * Config.touchLookSpeed, -lookY * Config.touchLookSpeed)
        for _, action in ipairs(touch:takeActions()) do
            interact(action)
        end
    end
    camera:move(dt, forward, right, up, speed)
    renderer:update()
end

function love.draw()
    renderer:draw(camera:viewProjection(love.graphics.getWidth() / love.graphics.getHeight()))
    drawCrosshair()
    if touchMode then
        touch:draw()
    end
    inputToggle:draw(touchMode)
end

-- Fingers, and the mouse acting as one in touch mode, go through these three.

local function pointerPressed(id, x, y)
    layoutUi() -- input may arrive before the first update
    if inputToggle:contains(x, y) then
        setTouchMode(not touchMode)
    elseif touchMode then
        touch:pressed(id, x, y)
    end
end

local function pointerMoved(id, x, y, dx, dy)
    if touchMode then
        touch:moved(id, x, y, dx, dy)
    end
end

local function pointerReleased(id)
    touch:released(id)
end

function love.touchpressed(id, x, y)
    pointerPressed(id, x, y)
end

function love.touchmoved(id, x, y, dx, dy)
    pointerMoved(id, x, y, dx, dy)
end

function love.touchreleased(id)
    pointerReleased(id)
end

-- Touches also arrive as emulated mouse events (`istouch`); those are ignored
-- below because the touch callbacks above already handle them.

function love.mousemoved(x, y, dx, dy, istouch)
    if istouch then
        return
    end
    if touchMode then
        pointerMoved(MOUSE_TOUCH_ID, x, y, dx, dy)
    elseif love.mouse.getRelativeMode() then
        local sensitivity = Config.mouseSensitivity
        camera:rotate(-dx * sensitivity, -dy * sensitivity)
    end
end

function love.mousepressed(x, y, button, istouch)
    if istouch then
        return
    end
    if touchMode then
        if button == 1 then
            pointerPressed(MOUSE_TOUCH_ID, x, y)
        end
        return
    end
    if not love.mouse.getRelativeMode() then
        -- The cursor is visible: it can reach the toggle; any other click only captures the mouse.
        layoutUi()
        if inputToggle:contains(x, y) then
            setTouchMode(true)
        else
            love.mouse.setRelativeMode(true)
        end
        return
    end
    if button == Config.mouseButtons.breakBlock then
        interact("break")
    elseif button == Config.mouseButtons.placeBlock then
        interact("place")
    end
end

function love.mousereleased(_, _, button, istouch)
    if touchMode and not istouch and button == 1 then
        pointerReleased(MOUSE_TOUCH_ID)
    end
end

function love.keypressed(key)
    if key == Config.keys.toggleInput then
        setTouchMode(not touchMode)
    -- In a browser, Esc already releases the mouse and quitting would just freeze the page.
    elseif key == Config.keys.quit and love.system.getOS() ~= "Web" then
        love.event.quit()
    end
end

function love.focus(focused)
    if not focused then
        love.mouse.setRelativeMode(false)
    end
end
