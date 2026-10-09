--- Fixed-size block grid.
--
-- Blocks are addressed by integer Vec3 positions with Z pointing up (same as
-- .vox). Block (x, y, z) occupies the unit cube [x, x+1] x [y, y+1] x [z, z+1].
-- Everything outside the grid reads as air and cannot be modified. Loading a
-- world from a file is src/world/load.lua.

local Blocks = require("src.world.blocks")

--- @class World
--- @field size Extent3 In blocks.
--- @field blocks BlockId[] Flat grid, indexed by `size:index(block) + 1`.
local World = {}
World.__index = World

local AIR = Blocks.AIR

--- Creates a world filled with air.
--- @param size Extent3
--- @return World
function World.new(size)
    assert(size.x >= 1 and size.y >= 1 and size.z >= 1, "world dimensions must be positive")
    local blocks = {}
    for i = 1, size:volume() do
        blocks[i] = AIR
    end
    return setmetatable({ size = size, blocks = blocks }, World)
end

--- @param block Vec3 Integer position.
--- @return BlockId
function World:get(block)
    if not self.size:contains(block) then
        return AIR
    end
    return self.blocks[self.size:index(block) + 1]
end

--- @param block Vec3 Integer position.
--- @return boolean
function World:isSolid(block)
    return self:get(block) ~= AIR
end

--- Sets a block. Returns true if the world changed.
--- @param block Vec3 Integer position.
--- @param id BlockId
--- @return boolean
function World:set(block, id)
    if not self.size:contains(block) then
        return false
    end
    local index = self.size:index(block) + 1
    if self.blocks[index] == id then
        return false
    end
    self.blocks[index] = id
    return true
end

return World
