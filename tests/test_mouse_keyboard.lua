local t = require("tests.lib")
local Config = require("src.config")
local FakeLove = require("tests.fake_love")
local MouseKeyboardInput = require("src.input.mouse_keyboard")

--- Registers a test that runs with a fake `love` and a fresh input.
--- @param name string
--- @param fn fun(input: MouseKeyboardInput, fake: FakeLove)
local function test(name, fn)
    t.test("mouse & keyboard: " .. name, function()
        FakeLove.run(function(fake) fn(MouseKeyboardInput.new(), fake) end)
    end)
end

test("captures the mouse and reads the keyboard", function(input, fake)
    t.eq(fake.captured, true)
    fake.keysDown[Config.keys.forward], fake.keysDown[Config.keys.fast] = true, true
    local frame = input:takeFrame()
    t.eq(frame.forward, 1); t.eq(frame.right, 0); t.eq(frame.up, 0); t.eq(frame.fast, true)
end)

test("mouse motion becomes look, once per frame", function(input)
    input:mousemoved(100, -50, false)
    local frame = input:takeFrame()
    t.near(frame.yaw, -100 * Config.mouseSensitivity)
    t.near(frame.pitch, 50 * Config.mouseSensitivity)
    t.eq(input:takeFrame().yaw, 0, "cleared after the frame")
end)

test("captured clicks break and place", function(input)
    input:mousepressed(Config.mouseButtons.breakBlock, false)
    input:mousepressed(Config.mouseButtons.placeBlock, false)
    local actions = input:takeFrame().actions
    t.eq(#actions, 2); t.eq(actions[1], "break"); t.eq(actions[2], "place")
end)

test("a click on the uncaptured window only recaptures the mouse", function(input, fake)
    fake.captured = false
    input:mousepressed(Config.mouseButtons.breakBlock, false)
    t.eq(fake.captured, true, "captured")
    t.eq(#input:takeFrame().actions, 0, "the capturing click does nothing else")
end)

test("mouse events emulated from touches are ignored", function(input)
    input:mousemoved(72, 0, true)
    input:mousepressed(Config.mouseButtons.breakBlock, true)
    local frame = input:takeFrame()
    t.eq(frame.yaw, 0); t.eq(#frame.actions, 0)
end)

test("losing focus releases the mouse", function(input, fake)
    input:focus(false)
    t.eq(fake.captured, false)
end)
