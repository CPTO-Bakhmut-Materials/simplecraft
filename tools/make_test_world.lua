--- Generates assets/worlds/test.vox: a small hilly island of stone, dirt and grass.
-- Run from the project root: `luajit tools/make_test_world.lua`

local Blocks = require("src.blocks")
local Extent3 = require("src.math.extent3")
local VoxWriter = require("tools.vox_writer")

local SIZE_X, SIZE_Y, SIZE_Z = 48, 48, 24
local OUTPUT = "assets/worlds/test.vox"

-- Palette index per block type; colors come from the block definitions so the
-- loader maps them back exactly.
local PALETTE_INDEX = { [Blocks.STONE] = 1, [Blocks.DIRT] = 2, [Blocks.GRASS] = 3 }

local function surfaceHeight(x, y)
    local h = 10 + 3 * math.sin(x / 6) + 3 * math.cos(y / 7) + 2 * math.sin((x + y) / 9)
    return math.max(4, math.min(SIZE_Z - 2, math.floor(h)))
end

local voxels = {}
local function add(x, y, z, block)
    local n = #voxels
    voxels[n + 1], voxels[n + 2], voxels[n + 3], voxels[n + 4] = x, y, z, PALETTE_INDEX[block]
end

for x = 0, SIZE_X - 1 do
    for y = 0, SIZE_Y - 1 do
        local height = surfaceHeight(x, y)
        for z = 0, height - 1 do
            local block = Blocks.STONE
            if z == height - 1 then
                block = Blocks.GRASS
            elseif z >= height - 4 then
                block = Blocks.DIRT
            end
            add(x, y, z, block)
        end
    end
end

-- A stone pillar to fly around.
for z = surfaceHeight(12, 12), SIZE_Z - 1 do
    for dx = 0, 1 do
        for dy = 0, 1 do
            add(12 + dx, 12 + dy, z, Blocks.STONE)
        end
    end
end

local palette = {}
for block, index in pairs(PALETTE_INDEX) do
    palette[index] = Blocks.defs[block].color
end

local file = assert(io.open(OUTPUT, "wb"))
file:write(VoxWriter.encode({ size = Extent3.new(SIZE_X, SIZE_Y, SIZE_Z), voxels = voxels }, palette))
file:close()
print(("wrote %s (%dx%dx%d, %d voxels)"):format(OUTPUT, SIZE_X, SIZE_Y, SIZE_Z, #voxels / 4))
