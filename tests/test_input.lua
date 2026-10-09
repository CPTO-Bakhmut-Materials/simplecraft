local t = require("tests.lib")
local Hud = require("src.hud")
local Input = require("src.input")

local CALLBACKS = { "touchpressed", "touchmoved", "touchreleased", "mousemoved", "mousepressed", "keypressed", "focus" }

--- Runs `fn` with a fresh fake `love` (Input.use registers callbacks on it), then restores the previous one.
--- @param fn fun(fake: table)
local function withFakeLove(fn)
    local previous = rawget(_G, "love")
    local fake = { mouse = { setRelativeMode = function() end, getRelativeMode = function() return false end } }
    rawset(_G, "love", fake)
    local ok, err = pcall(fn, fake)
    rawset(_G, "love", previous)
    if not ok then error(err, 0) end
end

--- @param fake table
--- @return string Names of the input callbacks registered on `fake`, space-separated.
local function registered(fake)
    local names = {}
    for _, name in ipairs(CALLBACKS) do
        if fake[name] then names[#names + 1] = name end
    end
    return table.concat(names, " ")
end

t.test("input: touch mode registers only touch callbacks", function()
    withFakeLove(function(fake)
        local input = Input.use(Hud.new(), true)
        t.eq(registered(fake), "touchpressed touchmoved touchreleased")
        t.ok(input.takeFrame ~= nil and input.draw ~= nil)
    end)
end)

t.test("input: mouse mode registers only mouse, keyboard and focus callbacks", function()
    withFakeLove(function(fake)
        local input = Input.use(Hud.new(), false)
        t.eq(registered(fake), "mousemoved mousepressed keypressed focus")
        t.ok(input.takeFrame ~= nil and input.draw ~= nil)
    end)
end)
