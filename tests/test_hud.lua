local t = require("tests.lib")
local Hud = require("src.hud")

local WIDTH, HEIGHT = 1280, 720

local function newHud(width, height)
    local hud = Hud.new()
    hud:resize(width or WIDTH, height or HEIGHT)
    return hud
end

t.test("hud: buttons sit in the bottom-right corner, inside the screen", function()
    local hud = newHud()
    t.eq(#hud.buttons, 4)
    for _, button in ipairs(hud.buttons) do
        t.ok(button.x > WIDTH / 2 and button.y > HEIGHT / 2, button.name .. " bottom-right")
        t.ok(button.x + button.radius <= WIDTH and button.y + button.radius <= HEIGHT, button.name .. " inside")
    end
end)

t.test("hud: hit test finds each button", function()
    local hud = newHud()
    for _, button in ipairs(hud.buttons) do
        t.eq(hud:hitTest(button.x, button.y), button.name)
        t.eq(hud:hitTest(button.x + button.radius * 1.1, button.y), button.name, "slightly outside the circle")
    end
end)

t.test("hud: hit test misses empty screen", function()
    local hud = newHud()
    t.eq(hud:hitTest(WIDTH / 2, HEIGHT / 2), nil)
    t.eq(hud:hitTest(hud.joystickHomeX, hud.joystickHomeY), nil, "the joystick area is not a target")
end)

t.test("hud: layout scales with the shorter screen side", function()
    local hud = newHud()
    local joystick, buttonRadius = hud.joystickRadius, hud.buttons[1].radius
    hud:resize(WIDTH * 2, HEIGHT * 2)
    t.near(hud.joystickRadius, joystick * 2)
    t.near(hud.buttons[1].radius, buttonRadius * 2)
    hud:resize(HEIGHT, WIDTH) -- portrait: the unit is now the width
    t.eq(hud.unit, HEIGHT)
    for _, button in ipairs(hud.buttons) do
        t.ok(button.x + button.radius <= HEIGHT, button.name .. " still inside")
    end
end)
