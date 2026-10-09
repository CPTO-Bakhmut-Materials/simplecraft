local t = require("tests.lib")
local Config = require("src.config")
local Hud = require("src.hud")
local Input = require("src.input")

local WIDTH, HEIGHT = 1280, 720

-- Input only touches love.mouse (capture) and love.keyboard (held keys); fake both.
local keysDown, captured = {}, false
rawset(_G, "love", {
    mouse = {
        setRelativeMode = function(enabled) captured = enabled end,
        getRelativeMode = function() return captured end,
    },
    keyboard = { isDown = function(key) return keysDown[key] == true end },
})

local function newInput(touchMode)
    keysDown, captured = {}, false
    local hud = Hud.new()
    hud:resize(WIDTH, HEIGHT)
    return Input.new(hud, touchMode), hud
end

t.test("input: mouse mode captures the mouse and reads the keyboard", function()
    local input = newInput(false)
    t.eq(captured, true)
    keysDown[Config.keys.forward], keysDown[Config.keys.fast] = true, true
    local frame = input:takeFrame()
    t.eq(frame.forward, 1); t.eq(frame.right, 0); t.eq(frame.fast, true)
end)

t.test("input: mouse mode turns mouse motion into look, once per frame", function()
    local input = newInput(false)
    input:mousemoved(100, -50, false)
    local frame = input:takeFrame()
    t.near(frame.yaw, -100 * Config.mouseSensitivity)
    t.near(frame.pitch, 50 * Config.mouseSensitivity)
    frame = input:takeFrame()
    t.eq(frame.yaw, 0, "cleared after take")
end)

t.test("input: captured clicks break and place", function()
    local input = newInput(false)
    input:mousepressed(Config.mouseButtons.breakBlock, false)
    input:mousepressed(Config.mouseButtons.placeBlock, false)
    local actions = input:takeFrame().actions
    t.eq(#actions, 2); t.eq(actions[1], "break"); t.eq(actions[2], "place")
end)

t.test("input: a click on the uncaptured window only recaptures the mouse", function()
    local input = newInput(false)
    captured = false
    input:mousepressed(Config.mouseButtons.breakBlock, false)
    t.eq(captured, true, "captured")
    t.eq(#input:takeFrame().actions, 0, "the capturing click does nothing else")
end)

t.test("input: mouse mode ignores touches", function()
    local input, hud = newInput(false)
    local button = hud.buttons[1]
    input:touchpressed("f", button.x, button.y)
    input:touchpressed("g", WIDTH * 0.2, HEIGHT * 0.6)
    input:touchmoved("g", WIDTH * 0.2, HEIGHT * 0.3, 0, -HEIGHT * 0.3)
    local frame = input:takeFrame()
    t.eq(#frame.actions, 0); t.eq(frame.forward, 0)
end)

t.test("input: touch mode ignores the keyboard and mouse look", function()
    local input = newInput(true)
    t.eq(captured, false)
    keysDown[Config.keys.forward], keysDown[Config.keys.up] = true, true
    local frame = input:takeFrame()
    t.eq(frame.forward, 0); t.eq(frame.up, 0); t.eq(frame.fast, false)
end)

t.test("input: touch mode ignores the mouse", function()
    local input = newInput(true)
    input:mousemoved(72, 0, false)
    input:mousepressed(1, false)
    local frame = input:takeFrame()
    t.eq(frame.yaw, 0); t.eq(#frame.actions, 0)
end)

t.test("input: touch mode reads touches", function()
    local input, hud = newInput(true)
    input:touchpressed("look", WIDTH * 0.5, HEIGHT * 0.3)
    input:touchmoved("look", WIDTH * 0.5 + 72, HEIGHT * 0.3, 72, 0)
    for _, button in ipairs(hud.buttons) do
        if button.name == "place" then
            input:touchpressed("tap", button.x, button.y)
        end
    end
    local frame = input:takeFrame()
    t.near(frame.yaw, -0.1 * Config.touchLookSpeed, "72 px of a 720 px screen is 0.1 unit")
    t.eq(frame.actions[1], "place")
end)

t.test("input: mouse events emulated from touches are ignored", function()
    local input = newInput(false)
    input:mousemoved(72, 0, true)
    input:mousepressed(Config.mouseButtons.breakBlock, true)
    local frame = input:takeFrame()
    t.eq(frame.yaw, 0); t.eq(#frame.actions, 0)
end)

t.test("input: losing focus releases the mouse", function()
    local input = newInput(false)
    input:focus(false)
    t.eq(captured, false)
end)
