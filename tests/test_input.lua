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
    return Input.new(hud, touchMode)
end

local function toggleCenter(input)
    local toggle = input.hud.toggle
    return toggle.x + toggle.width / 2, toggle.y + toggle.height / 2
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
    input:mousemoved(0, 0, 100, -50, false)
    local frame = input:takeFrame()
    t.near(frame.yaw, -100 * Config.mouseSensitivity)
    t.near(frame.pitch, 50 * Config.mouseSensitivity)
    frame = input:takeFrame()
    t.eq(frame.yaw, 0, "cleared after take")
end)

t.test("input: captured clicks break and place", function()
    local input = newInput(false)
    input:mousepressed(10, 10, Config.mouseButtons.breakBlock, false)
    input:mousepressed(10, 10, Config.mouseButtons.placeBlock, false)
    local actions = input:takeFrame().actions
    t.eq(#actions, 2); t.eq(actions[1], "break"); t.eq(actions[2], "place")
end)

t.test("input: an uncaptured click only captures, unless it hits the toggle", function()
    local input = newInput(false)
    captured = false
    input:mousepressed(WIDTH / 2, HEIGHT / 2, Config.mouseButtons.breakBlock, false)
    t.eq(captured, true, "captured")
    t.eq(#input:takeFrame().actions, 0, "the capturing click does nothing else")
    captured = false
    local x, y = toggleCenter(input)
    input:mousepressed(x, y, 1, false)
    t.eq(input.touchMode, true, "toggle switches to touch")
end)

t.test("input: mouse mode ignores touches except on the toggle", function()
    local input = newInput(false)
    local button = input.hud.buttons[1]
    input:touchpressed("f", button.x, button.y)
    input:touchpressed("g", WIDTH * 0.2, HEIGHT * 0.6)
    input:touchmoved("g", WIDTH * 0.2, HEIGHT * 0.3, 0, -HEIGHT * 0.3)
    local frame = input:takeFrame()
    t.eq(input.touchMode, false); t.eq(#frame.actions, 0); t.eq(frame.forward, 0)
    local x, y = toggleCenter(input)
    input:touchpressed("h", x, y)
    t.eq(input.touchMode, true)
end)

t.test("input: touch mode ignores the keyboard and mouse look", function()
    local input = newInput(true)
    t.eq(captured, false)
    keysDown[Config.keys.forward], keysDown[Config.keys.up] = true, true
    local frame = input:takeFrame()
    t.eq(frame.forward, 0); t.eq(frame.up, 0); t.eq(frame.fast, false)
end)

t.test("input: in touch mode the left mouse button acts as a finger", function()
    local input = newInput(true)
    input:mousepressed(WIDTH * 0.75, HEIGHT * 0.5, 1, false)
    input:mousemoved(WIDTH * 0.75 + 72, HEIGHT * 0.5, 72, 0, false)
    input:mousereleased(1, false)
    local frame = input:takeFrame()
    t.near(frame.yaw, -0.1 * Config.touchLookSpeed, "72 px of a 720 px screen is 0.1 unit")
    local button = input.hud.buttons[1]
    input:mousepressed(button.x, button.y, 1, false)
    t.eq(#input:takeFrame().actions, 1)
end)

t.test("input: touches emulated as mouse events are ignored", function()
    local input = newInput(true)
    input:mousepressed(WIDTH * 0.75, HEIGHT * 0.5, 1, true)
    input:mousemoved(WIDTH * 0.75 + 72, HEIGHT * 0.5, 72, 0, true)
    t.eq(input:takeFrame().yaw, 0)
end)

t.test("input: the toggle key switches modes and drops pending input", function()
    local input = newInput(false)
    input:mousemoved(0, 0, 100, 0, false)
    input:mousepressed(10, 10, Config.mouseButtons.breakBlock, false)
    input:keypressed(Config.keys.toggleInput)
    t.eq(input.touchMode, true); t.eq(captured, false)
    local frame = input:takeFrame()
    t.eq(frame.yaw, 0); t.eq(#frame.actions, 0)
    input:touchpressed("f", WIDTH * 0.2, HEIGHT * 0.6)
    input:keypressed(Config.keys.toggleInput)
    t.eq(input.touchMode, false)
    t.eq(input.touch:joystick(), nil, "held touches dropped")
end)

t.test("input: losing focus releases the mouse", function()
    local input = newInput(false)
    input:focus(false)
    t.eq(captured, false)
end)
