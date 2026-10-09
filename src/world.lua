--- Fixed-size block grid.
--
-- Coordinates are integer block positions with Z pointing up (same as .vox).
-- Block (x, y, z) occupies the unit cube [x, x+1] x [y, y+1] x [z, z+1].
-- Everything outside the grid reads as air and cannot be modified.

local Blocks = require("src.blocks")

--- @class World
--- @field sizeX integer
--- @field sizeY integer
--- @field sizeZ integer
--- @field blocks BlockId[] Flat grid, X fastest; see World:get.
local World = {}
World.__index = World

local AIR = Blocks.AIR

--- Creates a world filled with air.
--- @param sizeX integer
--- @param sizeY integer
--- @param sizeZ integer
--- @return World
function World.new(sizeX, sizeY, sizeZ)
    assert(sizeX >= 1 and sizeY >= 1 and sizeZ >= 1, "world dimensions must be positive")
    local blocks = {}
    for i = 1, sizeX * sizeY * sizeZ do
        blocks[i] = AIR
    end
    return setmetatable({ sizeX = sizeX, sizeY = sizeY, sizeZ = sizeZ, blocks = blocks }, World)
end

--- Builds a world from a parsed .vox file (see src/vox.lua).
--- Uses the first model; voxel colors are mapped to block types by Blocks.fromColor.
--- @param vox VoxFile
--- @return World
function World.fromVox(vox)
    if not vox.palette then
        error("world file has no color palette (RGBA chunk)", 0)
    end
    local model = vox.models[1]
    local world = World.new(model.sizeX, model.sizeY, model.sizeZ)

    local blockForIndex = {}
    for index, color in ipairs(vox.palette) do
        blockForIndex[index] = Blocks.fromColor(color[1], color[2], color[3])
    end

    local voxels = model.voxels
    for i = 1, model.count * 4, 4 do
        world:set(voxels[i], voxels[i + 1], voxels[i + 2], blockForIndex[voxels[i + 3]] or Blocks.STONE)
    end
    return world
end

--- @param x integer
--- @param y integer
--- @param z integer
--- @return boolean
function World:inBounds(x, y, z)
    return x >= 0 and y >= 0 and z >= 0 and x < self.sizeX and y < self.sizeY and z < self.sizeZ
end

--- @param x integer
--- @param y integer
--- @param z integer
--- @return BlockId
function World:get(x, y, z)
    if not self:inBounds(x, y, z) then
        return AIR
    end
    return self.blocks[x + self.sizeX * (y + self.sizeY * z) + 1]
end

--- @param x integer
--- @param y integer
--- @param z integer
--- @return boolean
function World:isSolid(x, y, z)
    return self:get(x, y, z) ~= AIR
end

--- Sets a block. Returns true if the world changed.
--- @param x integer
--- @param y integer
--- @param z integer
--- @param id BlockId
--- @return boolean
function World:set(x, y, z, id)
    if not self:inBounds(x, y, z) then
        return false
    end
    local index = x + self.sizeX * (y + self.sizeY * z) + 1
    if self.blocks[index] == id then
        return false
    end
    self.blocks[index] = id
    return true
end

return World
