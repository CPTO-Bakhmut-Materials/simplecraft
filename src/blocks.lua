--- Block type registry.
--
-- Block ids are small integers stored in the world grid (0 = air). Each solid
-- block names a texture layer for its top, side and bottom faces, plus a
-- reference color used to classify voxels when loading a .vox file.

local Blocks = {}

Blocks.AIR = 0
Blocks.STONE = 1
Blocks.DIRT = 2
Blocks.GRASS = 3

--- Texture files, in array-texture layer order (layer = index - 1).
Blocks.TEXTURES = { "stone.png", "dirt.png", "dirt_grass.png", "grass_top.png" }

local LAYER_STONE, LAYER_DIRT, LAYER_GRASS_SIDE, LAYER_GRASS_TOP = 0, 1, 2, 3

Blocks.defs = {
    [Blocks.STONE] = {
        name = "stone", color = { 125, 125, 125 },
        top = LAYER_STONE, side = LAYER_STONE, bottom = LAYER_STONE,
    },
    [Blocks.DIRT] = {
        name = "dirt", color = { 121, 85, 58 },
        top = LAYER_DIRT, side = LAYER_DIRT, bottom = LAYER_DIRT,
    },
    [Blocks.GRASS] = {
        name = "grass", color = { 95, 159, 53 },
        top = LAYER_GRASS_TOP, side = LAYER_GRASS_SIDE, bottom = LAYER_DIRT,
    },
}

--- Returns the solid block whose reference color is closest to (r, g, b).
-- Voxel editors assign palette indices themselves, so classifying by color is
-- the only mapping that survives a round trip through an external tool.
function Blocks.fromColor(r, g, b)
    local bestId, bestDistance = Blocks.STONE, math.huge
    for id, def in ipairs(Blocks.defs) do
        local dr, dg, db = r - def.color[1], g - def.color[2], b - def.color[3]
        local distance = dr * dr + dg * dg + db * db
        if distance < bestDistance then
            bestId, bestDistance = id, distance
        end
    end
    return bestId
end

return Blocks
