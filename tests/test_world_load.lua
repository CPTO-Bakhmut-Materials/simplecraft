local t = require("tests.lib")
local Blocks = require("src.world.blocks")
local Extent3 = require("src.math.extent3")
local Vec3 = require("src.math.vec3")
local Vox = require("src.world.vox")
local VoxWriter = require("tools.vox_writer")
local WorldLoader = require("src.world.load")

t.test("world load: fromVox maps palette colors to blocks", function()
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
    local world = WorldLoader.fromVox(Vox.parse(data))
    t.eq(world.size, Extent3.new(3, 1, 1))
    t.eq(world:get(Vec3.new(0, 0, 0)), Blocks.STONE)
    t.eq(world:get(Vec3.new(1, 0, 0)), Blocks.DIRT)
    t.eq(world:get(Vec3.new(2, 0, 0)), Blocks.GRASS)
end)

t.test("world load: fromVox requires a palette", function()
    local data = VoxWriter.encode({
        size = Extent3.new(1, 1, 1), voxels = { { position = Vec3.ZERO, colorIndex = 1 } },
    }, nil)
    t.raises(function() WorldLoader.fromVox(Vox.parse(data)) end, "no color palette")
end)
