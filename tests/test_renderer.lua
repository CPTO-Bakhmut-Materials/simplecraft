local t = require("tests.lib")
local Renderer = require("src.render.renderer")
local Vec3 = require("src.math.vec3")

--- @param chunks Vec3[]
--- @return string Chunks sorted and joined, for order-independent comparison.
local function describe(chunks)
    local names = {}
    for i, chunk in ipairs(chunks) do names[i] = tostring(chunk) end
    table.sort(names)
    return table.concat(names, " ")
end

t.test("renderer: a block inside a chunk only touches its own chunk", function()
    t.eq(describe(Renderer.chunksTouching(Vec3.new(5, 5, 5), 16)), describe({ Vec3.new(0, 0, 0) }))
end)

t.test("renderer: a block on a chunk border also touches the neighbor across it", function()
    t.eq(describe(Renderer.chunksTouching(Vec3.new(0, 5, 5), 16)),
        describe({ Vec3.new(0, 0, 0), Vec3.new(-1, 0, 0) }), "low x border")
    t.eq(describe(Renderer.chunksTouching(Vec3.new(15, 5, 5), 16)),
        describe({ Vec3.new(0, 0, 0), Vec3.new(1, 0, 0) }), "high x border")
end)

t.test("renderer: a block in a chunk corner touches a neighbor per border", function()
    t.eq(describe(Renderer.chunksTouching(Vec3.new(15, 16, 31), 16)), describe({
        Vec3.new(0, 1, 1), Vec3.new(1, 1, 1), Vec3.new(0, 0, 1), Vec3.new(0, 1, 2),
    }))
end)

t.test("renderer: negative block coordinates map to negative chunks", function()
    t.eq(describe(Renderer.chunksTouching(Vec3.new(-1, 0, 0), 16)), describe({
        Vec3.new(-1, 0, 0), Vec3.new(0, 0, 0), Vec3.new(-1, -1, 0), Vec3.new(-1, 0, -1),
    }))
end)
