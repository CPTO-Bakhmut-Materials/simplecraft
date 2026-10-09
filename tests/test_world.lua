local t = require("tests.lib")
local Blocks = require("src.blocks")
local Extent3 = require("src.math.extent3")
local Vox = require("src.vox")
local VoxWriter = require("tools.vox_writer")
local Vec3 = require("src.math.vec3")
local World = require("src.world")

t.test("world: starts empty", function()
    local world = World.new(Extent3.new(2, 3, 4))
    t.eq(world:get(Vec3.new(1, 2, 3)), Blocks.AIR)
    t.eq(world:isSolid(Vec3.new(0, 0, 0)), false)
end)

t.test("world: set/get round-trips and reports changes", function()
    local world = World.new(Extent3.new(4, 4, 4))
    t.eq(world:set(Vec3.new(1, 2, 3), Blocks.STONE), true)
    t.eq(world:get(Vec3.new(1, 2, 3)), Blocks.STONE)
    t.eq(world:set(Vec3.new(1, 2, 3), Blocks.STONE), false, "unchanged value")
    t.eq(world:get(Vec3.new(2, 1, 3)), Blocks.AIR, "neighbouring cell untouched")
end)

t.test("world: outside the grid is air and read-only", function()
    local world = World.new(Extent3.new(2, 2, 2))
    t.eq(world:get(Vec3.new(-1, 0, 0)), Blocks.AIR)
    t.eq(world:get(Vec3.new(0, 0, 2)), Blocks.AIR)
    t.eq(world:set(Vec3.new(2, 0, 0), Blocks.DIRT), false)
end)

t.test("blocks: classifies colors by nearest reference color", function()
    t.eq(Blocks.fromColor(130, 128, 120), Blocks.STONE)
    t.eq(Blocks.fromColor(110, 80, 50), Blocks.DIRT)
    t.eq(Blocks.fromColor(0, 255, 0), Blocks.GRASS)
end)

t.test("world: fromVox maps palette colors to blocks", function()
    local data = VoxWriter.encode(
        {
            size = Extent3.new(3, 1, 1),
            voxels = {
                { position = Vec3.new(0, 0, 0), colorIndex = 5 },
                { position = Vec3.new(1, 0, 0), colorIndex = 6 },
                { position = Vec3.new(2, 0, 0), colorIndex = 7 },
            },
        },
        { [5] = { 100, 100, 100 }, [6] = { 120, 80, 60 }, [7] = { 80, 200, 40 } })
    local world = World.fromVox(Vox.parse(data))
    t.eq(world.size, Extent3.new(3, 1, 1))
    t.eq(world:get(Vec3.new(0, 0, 0)), Blocks.STONE)
    t.eq(world:get(Vec3.new(1, 0, 0)), Blocks.DIRT)
    t.eq(world:get(Vec3.new(2, 0, 0)), Blocks.GRASS)
end)

t.test("world: fromVox requires a palette", function()
    local data = VoxWriter.encode({
        size = Extent3.new(1, 1, 1), voxels = { { position = Vec3.ZERO, colorIndex = 1 } },
    }, nil)
    t.raises(function() World.fromVox(Vox.parse(data)) end, "no color palette")
end)
