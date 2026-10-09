--- Mouse & keyboard input: the captured mouse looks around, WASD/Space/Shift
--- move, clicks break and place blocks, Esc quits and G toggles fullscreen.
--
-- Used instead of the touch controls for the whole session; see src/input/init.lua.

local Config = require("src.config")

--- @class MouseKeyboard
--- @field yaw number Mouse look since the last frame, radians.
--- @field pitch number
--- @field actions BlockAction[] Clicks since the last frame.
local MouseKeyboard = {}
MouseKeyboard.__index = MouseKeyboard

--- Captures the mouse.
--- @return MouseKeyboard
function MouseKeyboard.new()
    love.mouse.setRelativeMode(true)
    return setmetatable({ yaw = 0, pitch = 0, actions = {} }, MouseKeyboard)
end

--- @param positiveKey love.KeyConstant
--- @param negativeKey love.KeyConstant
--- @return number -1, 0 or 1
local function axis(positiveKey, negativeKey)
    return (love.keyboard.isDown(positiveKey) and 1 or 0) - (love.keyboard.isDown(negativeKey) and 1 or 0)
end

--- Returns this frame's input and clears what was collected for it.
--- @return InputFrame
function MouseKeyboard:takeFrame()
    local keys = Config.keys
    local frame = {
        forward = axis(keys.forward, keys.back), right = axis(keys.right, keys.left), up = axis(keys.up, keys.down),
        fast = love.keyboard.isDown(keys.fast),
        yaw = self.yaw, pitch = self.pitch,
        actions = self.actions,
    }
    self.yaw, self.pitch, self.actions = 0, 0, {}
    return frame
end

-- LÖVE callbacks, forwarded from main.lua. On a touchscreen, LÖVE also turns
-- touches into mouse events (`istouch`); those are ignored.

--- @param dx number
--- @param dy number
--- @param istouch boolean
function MouseKeyboard:mousemoved(dx, dy, istouch)
    if not istouch and love.mouse.getRelativeMode() then
        self.yaw = self.yaw - dx * Config.mouseSensitivity
        self.pitch = self.pitch - dy * Config.mouseSensitivity
    end
end

--- @param button number
--- @param istouch boolean
function MouseKeyboard:mousepressed(button, istouch)
    if istouch then
        return
    end
    if not love.mouse.getRelativeMode() then
        love.mouse.setRelativeMode(true) -- a click on the uncaptured window only recaptures the mouse
    elseif button == Config.mouseButtons.breakBlock then
        self.actions[#self.actions + 1] = "break"
    elseif button == Config.mouseButtons.placeBlock then
        self.actions[#self.actions + 1] = "place"
    end
end

--- @param key love.KeyConstant
function MouseKeyboard:keypressed(key) -- luacheck: ignore 212/self (a method like the other callbacks)
    -- In a browser, the page handles these keys: Esc releases the mouse (quitting
    -- would just freeze the page) and the fullscreen key uses the page's own
    -- fullscreen, which works more reliably than the game's window there.
    if love.system.getOS() == "Web" then
        return
    end
    if key == Config.keys.quit then
        love.event.quit()
    elseif key == Config.keys.fullscreen then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end

--- Mouse & keyboard have no on-screen controls (the crosshair is drawn by the game).
function MouseKeyboard:draw() end -- luacheck: ignore 212/self (same interface as the touch controls)

--- @param focused boolean
function MouseKeyboard:focus(focused) -- luacheck: ignore 212/self (a method like the other callbacks)
    if not focused then
        love.mouse.setRelativeMode(false)
    end
end

return MouseKeyboard
