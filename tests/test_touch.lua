local t = require("tests.lib")
local Config = require("src.config")
local TouchInput = require("src.input.touch")

local WIDTH, HEIGHT = 1280, 720 -- 720 px is the shorter side, so 72 px of drag is 0.1 unit
local LOOK_SPEED = Config.touchLookSpeed

local function newControls()
    return TouchInput.new(function() return WIDTH, HEIGHT end)
end

local function buttonNamed(controls, name)
    for _, button in ipairs(controls:currentLayout().buttons) do
        if button.name == name then return button end
    end
    error("no button " .. name)
end

t.test("touch: no touches means no input", function()
    local frame = newControls():takeFrame()
    t.eq(frame.forward, 0); t.eq(frame.right, 0); t.eq(frame.up, 0); t.eq(frame.fast, false)
    t.eq(frame.yaw, 0); t.eq(frame.pitch, 0); t.eq(#frame.actions, 0)
end)

t.test("touch: move keys move while held", function()
    local controls = newControls()
    local cases = { forward = { 1, 0 }, back = { -1, 0 }, right = { 0, 1 }, left = { 0, -1 } }
    for name, expected in pairs(cases) do
        local key = buttonNamed(controls, name)
        controls:pressed(name, key.x, key.y)
        local frame = controls:takeFrame()
        t.eq(frame.forward, expected[1], name .. " forward"); t.eq(frame.right, expected[2], name .. " right")
        controls:released(name)
    end
    local frame = controls:takeFrame()
    t.eq(frame.forward, 0, "released"); t.eq(frame.right, 0)
end)

t.test("touch: sliding across the keys switches direction", function()
    local controls = newControls()
    local forwardKey, rightKey = buttonNamed(controls, "forward"), buttonNamed(controls, "right")
    controls:pressed(1, forwardKey.x, forwardKey.y)
    controls:moved(1, rightKey.x, rightKey.y, rightKey.x - forwardKey.x, rightKey.y - forwardKey.y)
    local frame = controls:takeFrame()
    t.eq(frame.forward, 0); t.eq(frame.right, 1)
    controls:moved(1, WIDTH / 2, rightKey.y, WIDTH / 2 - rightKey.x, 0)
    frame = controls:takeFrame()
    t.eq(frame.forward, 0, "off the keys: nothing held"); t.eq(frame.right, 0)
    t.eq(frame.yaw, 0, "and it does not look")
end)

t.test("touch: the center of the keys is not a key", function()
    local controls = newControls()
    local forwardKey, backKey = buttonNamed(controls, "forward"), buttonNamed(controls, "back")
    t.eq(controls:currentLayout():hitTest(forwardKey.x, (forwardKey.y + backKey.y) / 2), nil)
end)

t.test("touch: a touch off the buttons looks, in units of the shorter side", function()
    local controls = newControls()
    controls:pressed("b", 900, 200)
    controls:moved("b", 972, 200, 72, 0)
    controls:moved("b", 972, 236, 0, 36)
    local frame = controls:takeFrame()
    t.near(frame.yaw, -0.1 * LOOK_SPEED); t.near(frame.pitch, -0.05 * LOOK_SPEED)
    t.eq(frame.forward, 0, "looking does not move")
    frame = controls:takeFrame()
    t.eq(frame.yaw, 0, "cleared after the frame"); t.eq(frame.pitch, 0)
end)

t.test("touch: tapping break/place queues actions in order", function()
    local controls = newControls()
    local breakButton, placeButton = buttonNamed(controls, "break"), buttonNamed(controls, "place")
    controls:pressed(1, breakButton.x, breakButton.y)
    controls:released(1)
    controls:pressed(2, placeButton.x, placeButton.y)
    local actions = controls:takeFrame().actions
    t.eq(#actions, 2); t.eq(actions[1], "break"); t.eq(actions[2], "place")
    t.eq(#controls:takeFrame().actions, 0, "cleared after the frame")
end)

t.test("touch: up/down fly only while held", function()
    local controls = newControls()
    local upButton, downButton = buttonNamed(controls, "up"), buttonNamed(controls, "down")
    controls:pressed(1, upButton.x, upButton.y)
    t.eq(controls:takeFrame().up, 1)
    controls:pressed(2, downButton.x, downButton.y)
    t.eq(controls:takeFrame().up, 0, "both held cancel out")
    controls:released(1)
    t.eq(controls:takeFrame().up, -1)
    controls:released(2)
    local frame = controls:takeFrame()
    t.eq(frame.up, 0)
    t.eq(#frame.actions, 0, "fly buttons are not actions")
end)

t.test("touch: dragging from a button does not look", function()
    local controls = newControls()
    local button = buttonNamed(controls, "place")
    controls:pressed(1, button.x, button.y)
    controls:moved(1, button.x - 50, button.y, -50, 0)
    t.eq(controls:takeFrame().yaw, 0)
end)

t.test("touch: moving, looking and tapping work at the same time", function()
    local controls = newControls()
    local key, place = buttonNamed(controls, "forward"), buttonNamed(controls, "place")
    controls:pressed("move", key.x, key.y)
    controls:pressed("look", 640, 200)
    controls:moved("look", 712, 200, 72, 0)
    controls:pressed("tap", place.x, place.y)
    local frame = controls:takeFrame()
    t.eq(frame.forward, 1)
    t.near(frame.yaw, -0.1 * LOOK_SPEED)
    t.eq(frame.actions[1], "place")
    frame = controls:takeFrame()
    t.eq(frame.forward, 1, "keys stay held"); t.eq(frame.yaw, 0); t.eq(#frame.actions, 0)
end)

t.test("touch: moves and releases of unknown touches are ignored", function()
    local controls = newControls()
    controls:moved("ghost", 10, 10, 5, 5)
    controls:released("ghost")
    t.eq(controls:takeFrame().yaw, 0)
end)

t.test("touch: the layout follows the screen size", function()
    local width, height = 1280, 720
    local controls = TouchInput.new(function() return width, height end)
    local before = buttonNamed(controls, "place")
    width, height = 2560, 1440
    local after = buttonNamed(controls, "place")
    t.near(after.x, before.x * 2); t.near(after.size, before.size * 2)
    controls:pressed(1, after.x, after.y)
    t.eq(controls:takeFrame().actions[1], "place", "touches hit the resized button")
end)
