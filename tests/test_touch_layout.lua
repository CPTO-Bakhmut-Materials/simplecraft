local t = require("tests.lib")
local TouchLayout = require("src.input.touch_layout")

local WIDTH, HEIGHT = 1280, 720

local function newLayout(width, height)
    local layout = TouchLayout.new()
    layout:resize(width or WIDTH, height or HEIGHT)
    return layout
end

local MOVE_KEYS = { forward = true, back = true, left = true, right = true }

t.test("layout: direction keys sit bottom-left, the other buttons bottom-right", function()
    local layout = newLayout()
    t.eq(#layout.buttons, 8)
    for _, button in ipairs(layout.buttons) do
        local isKey = MOVE_KEYS[button.name] == true
        t.eq(button.kind == "move", isKey, button.name .. " kind")
        t.eq(button.action, button.kind == "action" and button.name or nil, button.name .. " action")
        t.ok(isKey == (button.x < WIDTH / 2), button.name .. " side")
        t.ok(button.y > HEIGHT / 2, button.name .. " bottom half")
        t.ok(button.x - button.size >= 0 and button.x + button.size <= WIDTH
            and button.y + button.size <= HEIGHT, button.name .. " inside")
    end
end)

t.test("layout: direction keys form a plus around an empty center", function()
    local layout = newLayout()
    local keys = {}
    for _, button in ipairs(layout.buttons) do keys[button.name] = button end
    t.eq(keys.forward.x, keys.back.x); t.ok(keys.forward.y < keys.back.y)
    t.eq(keys.left.y, keys.right.y); t.ok(keys.left.x < keys.right.x)
    t.near(keys.left.y, (keys.forward.y + keys.back.y) / 2)
    t.eq(layout:hitTest(keys.forward.x, keys.left.y), nil, "center")
end)

t.test("layout: hit test finds each button", function()
    local layout = newLayout()
    for _, button in ipairs(layout.buttons) do
        t.eq(layout:hitTest(button.x, button.y), button)
        t.eq(layout:hitTest(button.x + button.size * 1.05, button.y), button, "slightly outside")
    end
end)

t.test("layout: hit test misses empty screen", function()
    local layout = newLayout()
    t.eq(layout:hitTest(WIDTH / 2, HEIGHT / 2), nil)
    t.eq(layout:hitTest(10, 10), nil, "top-left corner")
end)

t.test("layout: layout scales with the shorter screen side", function()
    local layout = newLayout()
    local sizes = {}
    for i, button in ipairs(layout.buttons) do sizes[i] = button.size end
    layout:resize(WIDTH * 2, HEIGHT * 2)
    for i, button in ipairs(layout.buttons) do t.near(button.size, sizes[i] * 2, button.name) end
    layout:resize(HEIGHT, WIDTH) -- portrait: the unit is now the width
    t.eq(layout.unit, HEIGHT)
    for _, button in ipairs(layout.buttons) do
        t.ok(button.x - button.size >= 0 and button.x + button.size <= HEIGHT, button.name .. " still inside")
    end
end)
