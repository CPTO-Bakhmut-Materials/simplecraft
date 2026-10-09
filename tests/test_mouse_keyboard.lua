local t = require("tests.lib")
local Config = require("src.config")
local MouseKeyboard = require("src.input.mouse_keyboard")

-- MouseKeyboard only touches love.mouse (capture) and love.keyboard (held keys); fake both.
local keysDown, captured = {}, false
rawset(_G, "love", {
    mouse = {
        setRelativeMode = function(enabled) captured = enabled end,
        getRelativeMode = function() return captured end,
    },
    keyboard = { isDown = function(key) return keysDown[key] == true end },
})

local function newInput()
    keysDown, captured = {}, false
    return MouseKeyboard.new()
end

t.test("mouse & keyboard: captures the mouse and reads the keyboard", function()
    local input = newInput()
    t.eq(captured, true)
    keysDown[Config.keys.forward], keysDown[Config.keys.fast] = true, true
    local frame = input:takeFrame()
    t.eq(frame.forward, 1); t.eq(frame.right, 0); t.eq(frame.up, 0); t.eq(frame.fast, true)
end)

t.test("mouse & keyboard: mouse motion becomes look, once per frame", function()
    local input = newInput()
    input:mousemoved(100, -50, false)
    local frame = input:takeFrame()
    t.near(frame.yaw, -100 * Config.mouseSensitivity)
    t.near(frame.pitch, 50 * Config.mouseSensitivity)
    frame = input:takeFrame()
    t.eq(frame.yaw, 0, "cleared after take")
end)

t.test("mouse & keyboard: captured clicks break and place", function()
    local input = newInput()
    input:mousepressed(Config.mouseButtons.breakBlock, false)
    input:mousepressed(Config.mouseButtons.placeBlock, false)
    local actions = input:takeFrame().actions
    t.eq(#actions, 2); t.eq(actions[1], "break"); t.eq(actions[2], "place")
end)

t.test("mouse & keyboard: a click on the uncaptured window only recaptures the mouse", function()
    local input = newInput()
    captured = false
    input:mousepressed(Config.mouseButtons.breakBlock, false)
    t.eq(captured, true, "captured")
    t.eq(#input:takeFrame().actions, 0, "the capturing click does nothing else")
end)

t.test("mouse & keyboard: mouse events emulated from touches are ignored", function()
    local input = newInput()
    input:mousemoved(72, 0, true)
    input:mousepressed(Config.mouseButtons.breakBlock, true)
    local frame = input:takeFrame()
    t.eq(frame.yaw, 0); t.eq(#frame.actions, 0)
end)

t.test("mouse & keyboard: losing focus releases the mouse", function()
    local input = newInput()
    input:focus(false)
    t.eq(captured, false)
end)
