local t = require("tests.lib")
local FakeLove = require("tests.fake_love")
local Input = require("src.input")

local CALLBACKS = { "touchpressed", "touchmoved", "touchreleased", "mousemoved", "mousepressed", "keypressed", "focus" }

--- @param fake FakeLove
--- @return string Names of the input callbacks registered on `fake`, space-separated.
local function registered(fake)
    local names = {}
    for _, name in ipairs(CALLBACKS) do
        if fake[name] then names[#names + 1] = name end
    end
    return table.concat(names, " ")
end

t.test("input: touch mode registers only touch callbacks", function()
    FakeLove.run(function(fake)
        local input = Input.use(true)
        t.eq(registered(fake), "touchpressed touchmoved touchreleased")
        t.ok(input.takeFrame ~= nil and input.draw ~= nil)
    end)
end)

t.test("input: mouse mode registers only mouse, keyboard and focus callbacks", function()
    FakeLove.run(function(fake)
        local input = Input.use(false)
        t.eq(registered(fake), "mousemoved mousepressed keypressed focus")
        t.ok(input.takeFrame ~= nil and input.draw ~= nil)
    end)
end)
