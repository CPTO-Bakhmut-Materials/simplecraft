local t = require("tests.lib")
local Hud = require("src.hud")

local WIDTH, HEIGHT = 1280, 720

local function newHud(width, height)
    local hud = Hud.new()
    hud:resize(width or WIDTH, height or HEIGHT)
    return hud
end

local DIRECTIONS = { forward = true, back = true, left = true, right = true }

t.test("hud: direction keys sit bottom-left, the other buttons bottom-right", function()
    local hud = newHud()
    t.eq(#hud.buttons, 8)
    for _, button in ipairs(hud.buttons) do
        local isKey = DIRECTIONS[button.name] == true
        t.eq(button.shape, isKey and "square" or "circle", button.name .. " shape")
        t.ok(isKey == (button.x < WIDTH / 2), button.name .. " side")
        t.ok(button.y > HEIGHT / 2, button.name .. " bottom half")
        t.ok(button.x - button.size >= 0 and button.x + button.size <= WIDTH
            and button.y + button.size <= HEIGHT, button.name .. " inside")
    end
end)

t.test("hud: direction keys form a plus around an empty center", function()
    local hud = newHud()
    local keys = {}
    for _, button in ipairs(hud.buttons) do keys[button.name] = button end
    t.eq(keys.forward.x, keys.back.x); t.ok(keys.forward.y < keys.back.y)
    t.eq(keys.left.y, keys.right.y); t.ok(keys.left.x < keys.right.x)
    t.near(keys.left.y, (keys.forward.y + keys.back.y) / 2)
    t.eq(hud:hitTest(keys.forward.x, keys.left.y), nil, "center")
end)

t.test("hud: hit test finds each button", function()
    local hud = newHud()
    for _, button in ipairs(hud.buttons) do
        t.eq(hud:hitTest(button.x, button.y), button.name)
        t.eq(hud:hitTest(button.x + button.size * 1.05, button.y), button.name, "slightly outside")
    end
end)

t.test("hud: hit test misses empty screen", function()
    local hud = newHud()
    t.eq(hud:hitTest(WIDTH / 2, HEIGHT / 2), nil)
    t.eq(hud:hitTest(10, 10), nil, "top-left corner")
end)

t.test("hud: layout scales with the shorter screen side", function()
    local hud = newHud()
    local sizes = {}
    for i, button in ipairs(hud.buttons) do sizes[i] = button.size end
    hud:resize(WIDTH * 2, HEIGHT * 2)
    for i, button in ipairs(hud.buttons) do t.near(button.size, sizes[i] * 2, button.name) end
    hud:resize(HEIGHT, WIDTH) -- portrait: the unit is now the width
    t.eq(hud.unit, HEIGHT)
    for _, button in ipairs(hud.buttons) do
        t.ok(button.x - button.size >= 0 and button.x + button.size <= HEIGHT, button.name .. " still inside")
    end
end)
