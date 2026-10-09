local t = require("tests.lib")
local Hud = require("src.hud")

local WIDTH, HEIGHT = 1280, 720

local function newHud(width, height)
    local hud = Hud.new()
    hud:resize(width or WIDTH, height or HEIGHT)
    return hud
end

t.test("hud: toggle sits in the top-right corner, inside the screen", function()
    local toggle = newHud().toggle
    t.ok(toggle.x > WIDTH / 2, "on the right half")
    t.ok(toggle.y + toggle.height < HEIGHT / 4, "near the top")
    t.ok(toggle.x + toggle.width <= WIDTH and toggle.y >= 0, "inside the screen")
end)

t.test("hud: buttons sit in the bottom-right corner, inside the screen", function()
    local hud = newHud()
    t.eq(#hud.buttons, 4)
    for _, button in ipairs(hud.buttons) do
        t.ok(button.x > WIDTH / 2 and button.y > HEIGHT / 2, button.name .. " bottom-right")
        t.ok(button.x + button.radius <= WIDTH and button.y + button.radius <= HEIGHT, button.name .. " inside")
    end
end)

t.test("hud: hit test finds the toggle and each button", function()
    local hud = newHud()
    local toggle = hud.toggle
    t.eq(hud:hitTest(toggle.x + toggle.width / 2, toggle.y + toggle.height / 2), "toggle")
    t.eq(hud:hitTest(toggle.x - 5, toggle.y - 5), "toggle", "padding just outside the corner")
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
    local joystick, toggleWidth = hud.joystickRadius, hud.toggle.width
    hud:resize(WIDTH * 2, HEIGHT * 2)
    t.near(hud.joystickRadius, joystick * 2)
    t.near(hud.toggle.width, toggleWidth * 2)
    hud:resize(HEIGHT, WIDTH) -- portrait: the unit is now the width
    t.eq(hud.unit, HEIGHT)
    t.ok(hud.toggle.x + hud.toggle.width <= HEIGHT, "toggle still inside")
end)
