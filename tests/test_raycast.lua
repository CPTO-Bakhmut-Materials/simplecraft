local t = require("tests.lib")
local Vec3 = require("src.math.vec3")
local Raycast = require("src.raycast")

-- Centre of block (0, 0, 0), the origin of most test rays.
local CENTER = Vec3.new(0.5, 0.5, 0.5)

local function solidAt(x, y, z)
    local solid = Vec3.new(x, y, z)
    return function(block) return block == solid end
end

t.test("raycast: hits block ahead and reports entry face", function()
    local hit = assert(Raycast.cast(solidAt(5, 0, 0), CENTER, Vec3.new(1, 0, 0), 10), "expected a hit")
    t.eq(hit.block, Vec3.new(5, 0, 0))
    t.eq(hit.normal, Vec3.new(-1, 0, 0))
end)

t.test("raycast: hits from above report a +Z normal", function()
    local hit = assert(Raycast.cast(solidAt(2, 3, 0), Vec3.new(2.5, 3.5, 6.2), Vec3.new(0, 0, -1), 10),
        "expected a hit")
    t.eq(hit.block.z, 0); t.eq(hit.normal, Vec3.new(0, 0, 1))
end)

t.test("raycast: misses beyond max distance", function()
    t.eq(Raycast.cast(solidAt(9, 0, 0), CENTER, Vec3.new(1, 0, 0), 5), nil)
end)

t.test("raycast: misses when nothing is in the way", function()
    t.eq(Raycast.cast(solidAt(0, 5, 0), CENTER, Vec3.new(1, 0, 0), 20), nil)
end)

t.test("raycast: handles negative coordinates and directions", function()
    local hit = assert(Raycast.cast(solidAt(-3, 0, 0), CENTER, Vec3.new(-1, 0, 0), 10), "expected a hit")
    t.eq(hit.block.x, -3); t.eq(hit.normal, Vec3.new(1, 0, 0))
end)

t.test("raycast: diagonal ray reaches the right cell", function()
    local d = 1 / math.sqrt(2)
    local hit = assert(Raycast.cast(solidAt(3, 3, 0), Vec3.new(0.5, 0.2, 0.5), Vec3.new(d, d, 0), 10), "expected a hit")
    t.eq(hit.block.x, 3); t.eq(hit.block.y, 3)
end)

t.test("raycast: origin inside a block reports a zero normal", function()
    local hit = assert(Raycast.cast(solidAt(0, 0, 0), CENTER, Vec3.new(0, 0, 1), 10), "expected a hit")
    t.eq(hit.normal, Vec3.new(0, 0, 0))
end)
