local t = require("tests.lib")
local TouchControls = require("src.touch_controls")

local WIDTH, HEIGHT = 1280, 720

local function newControls()
    local controls = TouchControls.new()
    controls:resize(WIDTH, HEIGHT)
    return controls
end

local function buttonNamed(controls, name)
    for _, button in ipairs(controls.buttons) do
        if button.name == name then return button end
    end
    error("no button " .. name)
end

t.test("touch: no touches means no input", function()
    local controls = newControls()
    local forward, right, up = controls:movement()
    t.eq(forward, 0); t.eq(right, 0); t.eq(up, 0)
    local dx, dy = controls:takeLook()
    t.eq(dx, 0); t.eq(dy, 0)
    t.eq(#controls:takeActions(), 0)
end)

t.test("touch: left half is a joystick centered where the touch lands", function()
    local controls = newControls()
    local radius = controls.joystickRadius
    controls:pressed("a", 300, 400)
    controls:moved("a", 300, 400 - radius / 2, 0, -radius / 2) -- push up: half forward
    local forward, right = controls:movement()
    t.near(forward, 0.5); t.near(right, 0)
    controls:moved("a", 300 + radius * 3, 400, radius * 3, 0) -- far right: clamped
    forward, right = controls:movement()
    t.near(forward, 0); t.near(right, 1)
end)

t.test("touch: small joystick movements are ignored", function()
    local controls = newControls()
    controls:pressed("a", 300, 400)
    controls:moved("a", 302, 401, 2, 1)
    local forward, right = controls:movement()
    t.eq(forward, 0); t.eq(right, 0)
end)

t.test("touch: right half drags the view in units of the shorter side", function()
    local controls = newControls()
    controls:pressed("b", 900, 200)
    controls:moved("b", 972, 200, 72, 0)
    controls:moved("b", 972, 236, 0, 36)
    local dx, dy = controls:takeLook()
    t.near(dx, 0.1); t.near(dy, 0.05)
    dx, dy = controls:takeLook()
    t.eq(dx, 0, "reset after take"); t.eq(dy, 0)
    local forward = controls:movement()
    t.eq(forward, 0, "looking does not move")
end)

t.test("touch: tapping break/place queues actions in order", function()
    local controls = newControls()
    local breakButton, placeButton = buttonNamed(controls, "break"), buttonNamed(controls, "place")
    controls:pressed(1, breakButton.x, breakButton.y)
    controls:released(1)
    controls:pressed(2, placeButton.x, placeButton.y)
    local actions = controls:takeActions()
    t.eq(#actions, 2); t.eq(actions[1], "break"); t.eq(actions[2], "place")
    t.eq(#controls:takeActions(), 0, "cleared after take")
end)

t.test("touch: up/down fly only while held", function()
    local controls = newControls()
    local upButton, downButton = buttonNamed(controls, "up"), buttonNamed(controls, "down")
    controls:pressed(1, upButton.x, upButton.y)
    local _, _, up = controls:movement()
    t.eq(up, 1)
    controls:pressed(2, downButton.x, downButton.y)
    _, _, up = controls:movement()
    t.eq(up, 0, "both held cancel out")
    controls:released(1)
    _, _, up = controls:movement()
    t.eq(up, -1)
    controls:released(2)
    _, _, up = controls:movement()
    t.eq(up, 0)
    t.eq(#controls:takeActions(), 0, "fly buttons are not actions")
end)

t.test("touch: buttons win over the joystick and look areas", function()
    local controls = newControls()
    local button = buttonNamed(controls, "place")
    controls:pressed(1, button.x, button.y)
    controls:moved(1, button.x - 50, button.y, -50, 0)
    local dx = controls:takeLook()
    t.eq(dx, 0, "dragging from a button does not look")
end)

t.test("touch: joystick and look work at the same time", function()
    local controls = newControls()
    local radius = controls.joystickRadius
    controls:pressed("move", 200, 500)
    controls:pressed("look", 1000, 200)
    controls:moved("move", 200, 500 - radius, 0, -radius)
    controls:moved("look", 1036, 200, 36, 0)
    local forward = controls:movement()
    local dx = controls:takeLook()
    t.near(forward, 1); t.near(dx, 0.05)
    controls:released("move")
    forward = controls:movement()
    t.eq(forward, 0, "joystick released")
end)

t.test("touch: layout scales with the screen and stays on it", function()
    local controls = newControls()
    local small = controls.joystickRadius
    controls:resize(WIDTH * 2, HEIGHT * 2)
    t.near(controls.joystickRadius, small * 2)
    for _, button in ipairs(controls.buttons) do
        t.ok(button.x + button.radius <= WIDTH * 2 and button.y + button.radius <= HEIGHT * 2,
            button.name .. " inside the screen")
        t.ok(button.x > WIDTH, button.name .. " on the right half")
    end
end)

t.test("touch: moves and releases of unknown touches are ignored", function()
    local controls = newControls()
    controls:moved("ghost", 10, 10, 5, 5)
    controls:released("ghost")
    local dx = controls:takeLook()
    t.eq(dx, 0)
end)
