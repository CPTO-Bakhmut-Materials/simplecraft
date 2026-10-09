--- Turns LÖVE's keyboard, mouse and touch events into one result per frame.
--
-- Input is in one of two modes, never chosen on the fly: mouse & keyboard
-- (captured mouse looks, WASD moves, clicks break/place) or touch (the
-- on-screen controls, see src/touch_controls.lua). Only the HUD toggle or the
-- toggle key switches, and each mode reads only its own input. In touch mode
-- the left mouse button acts as a finger, so the touch controls also work with
-- a mouse; in mouse mode, touches only reach the toggle.

local Config = require("src.config")
local TouchControls = require("src.touch_controls")

--- @alias BlockAction "break"|"place"

--- @class InputFrame
--- @field forward number -1..1 each, as Camera:move takes them.
--- @field right number
--- @field up number
--- @field fast boolean Move faster (keyboard only).
--- @field yaw number Camera rotation since the last frame, radians, as Camera:rotate takes them.
--- @field pitch number
--- @field actions BlockAction[] Oldest first.

--- @class Input
--- @field hud Hud Layout, for hit-testing the toggle and buttons.
--- @field touch TouchControls
--- @field touchMode boolean
--- @field mouseYaw number Mouse look since the last frame, radians.
--- @field mousePitch number
--- @field mouseActions BlockAction[] Clicks since the last frame.
local Input = {}
Input.__index = Input

local MOUSE_TOUCH_ID = "mouse" -- touch id for the mouse acting as a finger

--- @param hud Hud
--- @param touchMode boolean Starting mode.
--- @return Input
function Input.new(hud, touchMode)
    local self = setmetatable({
        hud = hud,
        touch = TouchControls.new(hud),
        touchMode = touchMode,
        mouseYaw = 0, mousePitch = 0, mouseActions = {},
    }, Input)
    love.mouse.setRelativeMode(not touchMode)
    return self
end

--- Switches modes and drops input pending from the old one. The mouse is left
--- uncaptured either way: in mouse mode the next click captures it.
--- @param enabled boolean
function Input:setTouchMode(enabled)
    self.touchMode = enabled
    self.touch:reset()
    self.mouseYaw, self.mousePitch, self.mouseActions = 0, 0, {}
    love.mouse.setRelativeMode(false)
end

--- @param positiveKey love.KeyConstant
--- @param negativeKey love.KeyConstant
--- @return number -1, 0 or 1
local function axis(positiveKey, negativeKey)
    return (love.keyboard.isDown(positiveKey) and 1 or 0) - (love.keyboard.isDown(negativeKey) and 1 or 0)
end

--- Returns this frame's input and clears what was collected for it.
--- @return InputFrame
function Input:takeFrame()
    if self.touchMode then
        local forward, right, up = self.touch:movement()
        local lookX, lookY = self.touch:takeLook()
        local lookSpeed = Config.touchLookSpeed
        return {
            forward = forward, right = right, up = up, fast = false,
            yaw = -lookX * lookSpeed, pitch = -lookY * lookSpeed,
            actions = self.touch:takeActions(),
        }
    end
    local keys = Config.keys
    local frame = {
        forward = axis(keys.forward, keys.back), right = axis(keys.right, keys.left), up = axis(keys.up, keys.down),
        fast = love.keyboard.isDown(keys.fast),
        yaw = self.mouseYaw, pitch = self.mousePitch,
        actions = self.mouseActions,
    }
    self.mouseYaw, self.mousePitch, self.mouseActions = 0, 0, {}
    return frame
end

-- Fingers, and the mouse acting as one in touch mode, go through these.

--- @param id any
--- @param x number
--- @param y number
function Input:pointerPressed(id, x, y)
    if self.hud:hitTest(x, y) == "toggle" then
        self:setTouchMode(not self.touchMode)
    elseif self.touchMode then
        self.touch:pressed(id, x, y)
    end
end

--- @param id any
--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
function Input:pointerMoved(id, x, y, dx, dy)
    if self.touchMode then
        self.touch:moved(id, x, y, dx, dy)
    end
end

-- LÖVE callbacks, forwarded from main.lua. Touches also arrive as emulated
-- mouse events (`istouch`); the mouse callbacks ignore those, since the touch
-- callbacks already handle them.

--- @param id any
--- @param x number
--- @param y number
function Input:touchpressed(id, x, y)
    self:pointerPressed(id, x, y)
end

--- @param id any
--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
function Input:touchmoved(id, x, y, dx, dy)
    self:pointerMoved(id, x, y, dx, dy)
end

--- @param id any
function Input:touchreleased(id)
    self.touch:released(id)
end

--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
--- @param istouch boolean
function Input:mousemoved(x, y, dx, dy, istouch)
    if istouch then
        return
    end
    if self.touchMode then
        self:pointerMoved(MOUSE_TOUCH_ID, x, y, dx, dy)
    elseif love.mouse.getRelativeMode() then
        self.mouseYaw = self.mouseYaw - dx * Config.mouseSensitivity
        self.mousePitch = self.mousePitch - dy * Config.mouseSensitivity
    end
end

--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
function Input:mousepressed(x, y, button, istouch)
    if istouch then
        return
    end
    if self.touchMode then
        if button == 1 then
            self:pointerPressed(MOUSE_TOUCH_ID, x, y)
        end
    elseif not love.mouse.getRelativeMode() then
        -- The cursor is visible, so it can reach the toggle; any other click only captures the mouse.
        if self.hud:hitTest(x, y) == "toggle" then
            self:setTouchMode(true)
        else
            love.mouse.setRelativeMode(true)
        end
    elseif button == Config.mouseButtons.breakBlock then
        self.mouseActions[#self.mouseActions + 1] = "break"
    elseif button == Config.mouseButtons.placeBlock then
        self.mouseActions[#self.mouseActions + 1] = "place"
    end
end

--- @param button number
--- @param istouch boolean
function Input:mousereleased(button, istouch)
    if self.touchMode and not istouch and button == 1 then
        self.touch:released(MOUSE_TOUCH_ID)
    end
end

--- @param key love.KeyConstant
function Input:keypressed(key)
    if key == Config.keys.toggleInput then
        self:setTouchMode(not self.touchMode)
    end
end

--- @param focused boolean
function Input:focus(focused) -- luacheck: ignore 212/self (a method like the other callbacks)
    if not focused then
        love.mouse.setRelativeMode(false)
    end
end

return Input
