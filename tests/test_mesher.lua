local t = require("tests.lib")
local Blocks = require("src.world.blocks")
local Extent3 = require("src.math.extent3")
local Vec3 = require("src.math.vec3")
local Mesher = require("src.render.mesher")
local World = require("src.world.world")

local VERTICES_PER_FACE = 6

t.test("mesher: lone block emits six faces", function()
    local world = World.new(Extent3.new(3, 3, 3))
    world:set(Vec3.new(1, 1, 1), Blocks.STONE)
    t.eq(#Mesher.buildChunk(world, Vec3.ZERO, 16), 6 * VERTICES_PER_FACE)
end)

t.test("mesher: empty world emits nothing", function()
    t.eq(#Mesher.buildChunk(World.new(Extent3.new(4, 4, 4)), Vec3.ZERO, 16), 0)
end)

t.test("mesher: shared faces are culled", function()
    local world = World.new(Extent3.new(3, 3, 3))
    world:set(Vec3.new(0, 0, 0), Blocks.STONE)
    world:set(Vec3.new(1, 0, 0), Blocks.DIRT)
    t.eq(#Mesher.buildChunk(world, Vec3.ZERO, 16), 10 * VERTICES_PER_FACE)
end)

t.test("mesher: culls against blocks in neighbouring chunks", function()
    local world = World.new(Extent3.new(4, 1, 1))
    world:set(Vec3.new(1, 0, 0), Blocks.STONE)
    world:set(Vec3.new(2, 0, 0), Blocks.STONE)
    -- Chunk size 2: block (1,0,0) is in chunk 0, its +X neighbour in chunk 1.
    t.eq(#Mesher.buildChunk(world, Vec3.ZERO, 2), 5 * VERTICES_PER_FACE)
end)

t.test("mesher: grass uses top, side and bottom layers", function()
    local world = World.new(Extent3.new(1, 1, 1))
    world:set(Vec3.new(0, 0, 0), Blocks.GRASS)
    local layerByNormal = {}
    local vertices = Mesher.buildChunk(world, Vec3.ZERO, 16)
    for i = 1, #vertices, VERTICES_PER_FACE do
        local zs = vertices[i][3] + vertices[i + 1][3] + vertices[i + 2][3]
        local kind = (zs == 3 and "top") or (zs == 0 and "bottom") or "side"
        layerByNormal[kind] = vertices[i][6]
    end
    t.eq(layerByNormal.top, Blocks.textureLayer(Blocks.GRASS, "top"))
    t.eq(layerByNormal.side, Blocks.textureLayer(Blocks.GRASS, "side"))
    t.eq(layerByNormal.bottom, Blocks.textureLayer(Blocks.GRASS, "bottom"))
    t.ok(layerByNormal.top ~= layerByNormal.side and layerByNormal.side ~= layerByNormal.bottom,
        "three different layers")
end)

t.test("mesher: triangles wind counter-clockwise seen from outside", function()
    local world = World.new(Extent3.new(1, 1, 1))
    world:set(Vec3.new(0, 0, 0), Blocks.STONE)
    local vertices = Mesher.buildChunk(world, Vec3.ZERO, 16)
    for i = 1, #vertices, 3 do
        local a, b, c = vertices[i], vertices[i + 1], vertices[i + 2]
        local ux, uy, uz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
        local vx, vy, vz = c[1] - a[1], c[2] - a[2], c[3] - a[3]
        local nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
        -- Direction from cube centre to triangle centroid must agree with the normal.
        local ox = (a[1] + b[1] + c[1]) / 3 - 0.5
        local oy = (a[2] + b[2] + c[2]) / 3 - 0.5
        local oz = (a[3] + b[3] + c[3]) / 3 - 0.5
        t.ok(nx * ox + ny * oy + nz * oz > 0, "triangle " .. ((i - 1) / 3 + 1) .. " faces inward")
    end
end)

t.test("mesher: side textures are upright", function()
    local world = World.new(Extent3.new(1, 1, 1))
    world:set(Vec3.new(0, 0, 0), Blocks.STONE)
    for _, vertex in ipairs(Mesher.buildChunk(world, Vec3.ZERO, 16)) do
        local isSideFace = vertex[7] < 1 and vertex[7] > 0.5
        if isSideFace then
            -- Texture v runs top (0) to bottom (1), so v must be 1 - z.
            t.eq(vertex[5], 1 - vertex[3])
        end
    end
end)
