--- Size of a 3D grid of cells, e.g. a world in blocks or a world in chunks.
--
-- Cells have 0-based integer coordinates and are flattened with X varying
-- fastest, then Y, then Z (see Extent3:index). Immutable, like Vec3. Methods
-- take plain coordinates so they can be used inside hot loops.

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

--- @param x integer
--- @param y integer
--- @param z integer
--- @return boolean
function Extent3:contains(x, y, z)
    return x >= 0 and y >= 0 and z >= 0 and x < self.x and y < self.y and z < self.z
end

--- Flat 0-based index of cell (x, y, z), which must be inside the extent.
--- @param x integer
--- @param y integer
--- @param z integer
--- @return integer
function Extent3:index(x, y, z)
    return x + self.x * (y + self.y * z)
end

--- Inverse of Extent3:index.
--- @param index integer
--- @return integer x, integer y, integer z
function Extent3:cell(index)
    return index % self.x, math.floor(index / self.x) % self.y, math.floor(index / (self.x * self.y))
end

return Extent3
