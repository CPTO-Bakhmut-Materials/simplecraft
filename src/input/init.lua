--- Player input: mouse & keyboard (src/input/mouse_keyboard.lua) or the
--- on-screen touch controls (src/input/touch.lua).
--
-- Only one input type is used per session. Input.use creates it and registers
-- the LÖVE callbacks of that type alone, so the other type's events are never
-- handled. Either input hands its result to the game once per frame through
-- takeFrame(), and draws its own on-screen controls with draw().

local MouseKeyboard = require("src.input.mouse_keyboard")
local TouchInput = require("src.input.touch")

--- @alias BlockAction "break"|"place"

--- What the input produced since the last frame.
--- @class InputFrame
--- @field forward number -1..1 each, as Camera:move takes them.
--- @field right number
--- @field up number
--- @field fast boolean Move faster (keyboard only).
--- @field yaw number Camera rotation since the last frame, radians, as Camera:rotate takes them.
--- @field pitch number
--- @field actions BlockAction[] Oldest first.

local Input = {}

--- Sets up the session's input and registers its LÖVE callbacks.
--- @param touchMode boolean Touch controls instead of mouse & keyboard.
--- @return MouseKeyboard|TouchInput input Call takeFrame() and draw() on it once per frame.
function Input.use(touchMode)
    if touchMode then
        local touch = TouchInput.new(love.graphics.getDimensions)
        function love.touchpressed(id, x, y) touch:pressed(id, x, y) end
        function love.touchmoved(id, x, y, dx, dy) touch:moved(id, x, y, dx, dy) end
        function love.touchreleased(id) touch:released(id) end
        return touch
    end
    local mouseKeyboard = MouseKeyboard.new()
    function love.mousemoved(_, _, dx, dy, istouch) mouseKeyboard:mousemoved(dx, dy, istouch) end
    function love.mousepressed(_, _, button, istouch) mouseKeyboard:mousepressed(button, istouch) end
    function love.keypressed(key) mouseKeyboard:keypressed(key) end
    function love.focus(focused) mouseKeyboard:focus(focused) end
    return mouseKeyboard
end

return Input
