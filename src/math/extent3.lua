--- Size of a 3D grid of cells, e.g. a world in blocks or a world in chunks.
--
-- Cells have 0-based integer coordinates (Vec3s) and are flattened with X
-- varying fastest, then Y, then Z (see Extent3:index). Immutable, like Vec3.

local Vec3 = require("src.math.vec3")

--- @class Extent3
--- @field x integer Number of cells along each axis.
--- @field y integer
--- @field z integer
local Extent3 = {}
Extent3.__index = Extent3

--- @param x integer
--- @param y integer
--- @param z integer
--- @return Extent3
function Extent3.new(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, Extent3)
end

--- @param a Extent3
--- @param b Extent3
--- @return boolean
function Extent3.__eq(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

--- @param a Extent3
--- @return string
function Extent3.__tostring(a)
    return ("%dx%dx%d"):format(a.x, a.y, a.z)
end

--- Total number of cells.
--- @return integer
function Extent3:volume()
    return self.x * self.y * self.z
end

--- Number of `divisor`-sized cells needed to cover this extent, e.g. a world
--- size in blocks divided by the chunk size gives the world size in chunks.
--- @param divisor integer
--- @return Extent3
function Extent3:divideRoundingUp(divisor)
    return Extent3.new(math.ceil(self.x / divisor), math.ceil(self.y / divisor), math.ceil(self.z / divisor))
end

--- @param cell Vec3 Integer coordinates.
--- @return boolean
function Extent3:contains(cell)
    return cell.x >= 0 and cell.y >= 0 and cell.z >= 0 and cell.x < self.x and cell.y < self.y and cell.z < self.z
end

--- Flat 0-based index of a cell, which must be inside the extent.
--- @param cell Vec3 Integer coordinates.
--- @return integer
function Extent3:index(cell)
    return cell.x + self.x * (cell.y + self.y * cell.z)
end

--- Inverse of Extent3:index.
--- @param index integer
--- @return Vec3
function Extent3:cell(index)
    return Vec3.new(index % self.x, math.floor(index / self.x) % self.y, math.floor(index / (self.x * self.y)))
end

return Extent3
