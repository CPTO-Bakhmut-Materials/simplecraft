--- Block type registry.
--
-- Block ids are small integers stored in the world grid (0 = air). Each solid
-- block names the texture file for its top, side and bottom faces, plus a
-- reference color used to classify voxels when loading a .vox file.

--- @alias BlockId integer 0 is air; see the constants below.
--- @alias BlockFace "top"|"side"|"bottom"

--- @class BlockDef
--- @field name string
--- @field color integer[] Reference `{ r, g, b }`, 0..255.
--- @field top string Texture file (in Config.textureDir) for each face direction.
--- @field side string
--- @field bottom string

local Blocks = {}

Blocks.AIR = 0
Blocks.STONE = 1
Blocks.DIRT = 2
Blocks.GRASS = 3

--- @type table<BlockId, BlockDef>
Blocks.defs = {
    [Blocks.STONE] = {
        name = "stone", color = { 125, 125, 125 },
        top = "stone.png", side = "stone.png", bottom = "stone.png",
    },
    [Blocks.DIRT] = {
        name = "dirt", color = { 121, 85, 58 },
        top = "dirt.png", side = "dirt.png", bottom = "dirt.png",
    },
    [Blocks.GRASS] = {
        name = "grass", color = { 95, 159, 53 },
        top = "grass_top.png", side = "dirt_grass.png", bottom = "dirt.png",
    },
}

--- Every texture file the blocks use, once each, in array-texture layer order
--- (layer = index - 1). Built from Blocks.defs.
--- @type string[]
Blocks.TEXTURES = {}
local layerOfFile = {} --- @type table<string, integer>
for _, def in ipairs(Blocks.defs) do
    for _, face in ipairs({ "top", "side", "bottom" }) do
        local file = def[face]
        if not layerOfFile[file] then
            layerOfFile[file] = #Blocks.TEXTURES
            Blocks.TEXTURES[#Blocks.TEXTURES + 1] = file
        end
    end
end

--- Array-texture layer of a block face (see Blocks.TEXTURES).
--- @param id BlockId A solid block.
--- @param face BlockFace
--- @return integer
function Blocks.textureLayer(id, face)
    return layerOfFile[Blocks.defs[id][face]]
end

--- Returns the solid block whose reference color is closest to (r, g, b).
--- Voxel editors assign palette indices themselves, so classifying by color is
--- the only mapping that survives a round trip through an external tool.
--- @param r integer
--- @param g integer
--- @param b integer
--- @return BlockId
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
