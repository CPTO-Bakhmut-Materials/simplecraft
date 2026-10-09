local t = require("tests.lib")
local InputToggle = require("src.input_toggle")

local WIDTH, HEIGHT = 1280, 720

t.test("input toggle: sits in the top-right corner, inside the screen", function()
    local toggle = InputToggle.new()
    toggle:resize(WIDTH, HEIGHT)
    t.ok(toggle.x > WIDTH / 2, "on the right half")
    t.ok(toggle.y + toggle.height < HEIGHT / 4, "near the top")
    t.ok(toggle.x + toggle.width <= WIDTH and toggle.y >= 0, "inside the screen")
end)

t.test("input toggle: hit test covers the pill plus a little padding", function()
    local toggle = InputToggle.new()
    toggle:resize(WIDTH, HEIGHT)
    t.ok(toggle:contains(toggle.x + toggle.width / 2, toggle.y + toggle.height / 2), "center")
    t.ok(toggle:contains(toggle.x - 5, toggle.y - 5), "just outside the corner")
    t.ok(not toggle:contains(WIDTH / 2, HEIGHT / 2), "screen center")
    t.ok(not toggle:contains(toggle.x - toggle.width, toggle.y), "well to the left")
end)

t.test("input toggle: layout scales with the screen", function()
    local toggle = InputToggle.new()
    toggle:resize(WIDTH, HEIGHT)
    local width = toggle.width
    toggle:resize(WIDTH * 2, HEIGHT * 2)
    t.near(toggle.width, width * 2)
    t.ok(toggle.x + toggle.width <= WIDTH * 2)
end)
