local t = require("tests.lib")
local Raycast = require("src.raycast")

local function solidAt(bx, by, bz)
    return function(x, y, z) return x == bx and y == by and z == bz end
end

t.test("raycast: hits block ahead and reports entry face", function()
    local hit = Raycast.cast(solidAt(5, 0, 0), 0.5, 0.5, 0.5, 1, 0, 0, 10)
    t.ok(hit, "expected a hit")
    t.eq(hit.x, 5); t.eq(hit.y, 0); t.eq(hit.z, 0)
    t.eq(hit.nx, -1); t.eq(hit.ny, 0); t.eq(hit.nz, 0)
end)

t.test("raycast: hits from above report a +Z normal", function()
    local hit = Raycast.cast(solidAt(2, 3, 0), 2.5, 3.5, 6.2, 0, 0, -1, 10)
    t.ok(hit, "expected a hit")
    t.eq(hit.z, 0); t.eq(hit.nz, 1)
end)

t.test("raycast: misses beyond max distance", function()
    t.eq(Raycast.cast(solidAt(9, 0, 0), 0.5, 0.5, 0.5, 1, 0, 0, 5), nil)
end)

t.test("raycast: misses when nothing is in the way", function()
    t.eq(Raycast.cast(solidAt(0, 5, 0), 0.5, 0.5, 0.5, 1, 0, 0, 20), nil)
end)

t.test("raycast: handles negative coordinates and directions", function()
    local hit = Raycast.cast(solidAt(-3, 0, 0), 0.5, 0.5, 0.5, -1, 0, 0, 10)
    t.ok(hit, "expected a hit")
    t.eq(hit.x, -3); t.eq(hit.nx, 1)
end)

t.test("raycast: diagonal ray reaches the right cell", function()
    local d = 1 / math.sqrt(2)
    local hit = Raycast.cast(solidAt(3, 3, 0), 0.5, 0.2, 0.5, d, d, 0, 10)
    t.ok(hit, "expected a hit")
    t.eq(hit.x, 3); t.eq(hit.y, 3)
end)

t.test("raycast: origin inside a block reports a zero normal", function()
    local hit = Raycast.cast(solidAt(0, 0, 0), 0.5, 0.5, 0.5, 0, 0, 1, 10)
    t.ok(hit, "expected a hit")
    t.eq(hit.nx, 0); t.eq(hit.ny, 0); t.eq(hit.nz, 0)
end)
