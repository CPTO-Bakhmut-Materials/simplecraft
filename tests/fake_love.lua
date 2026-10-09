--- A minimal stand-in for LÖVE's global `love`, for testing input code outside
--- the engine: mouse capture, held keys and the screen size.

--- @class FakeLove
--- @field captured boolean Mouse capture (love.mouse.setRelativeMode).
--- @field keysDown table<string, boolean> Keys love.keyboard.isDown reports as held.
--- @field mouse table
--- @field keyboard table
--- @field graphics table

local FakeLove = {}

--- Runs `fn` with the global `love` replaced by a fresh fake, then puts the
--- previous `love` back, even if `fn` fails.
--- @param fn fun(fake: FakeLove)
function FakeLove.run(fn)
    local fake = { captured = false, keysDown = {} }
    fake.mouse = {
        setRelativeMode = function(enabled) fake.captured = enabled end,
        getRelativeMode = function() return fake.captured end,
    }
    fake.keyboard = { isDown = function(key) return fake.keysDown[key] == true end }
    fake.graphics = { getDimensions = function() return 1280, 720 end }

    local previous = rawget(_G, "love")
    rawset(_G, "love", fake)
    local ok, err = pcall(fn, fake)
    rawset(_G, "love", previous)
    if not ok then
        error(err, 0)
    end
end

return FakeLove
