--- 3D vector for positions, directions, normals and block/chunk coordinates.
--
-- Vectors are treated as immutable: operators and methods return new vectors,
-- so one can be shared freely. Never assign to `x`, `y` or `z` after creation.
-- All 3D math in the game goes through Vec3; the code favors readability over
-- avoiding the small table each vector costs.

--- @alias Axis "x"|"y"|"z"

--- @class Vec3
--- @field x number
--- @field y number
--- @field z number
--- @operator add(Vec3): Vec3
--- @operator sub(Vec3): Vec3
--- @operator mul(number): Vec3
--- @operator div(number): Vec3
--- @operator unm: Vec3
local Vec3 = {}
Vec3.__index = Vec3

--- The three axes, for code that treats them alike (`v[axis]`).
--- @type Axis[]
Vec3.AXES = { "x", "y", "z" }

--- @param x number
--- @param y number
--- @param z number
--- @return Vec3
function Vec3.new(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, Vec3)
end

--- @param a Vec3
--- @param b Vec3
--- @return Vec3
function Vec3.__add(a, b)
    return Vec3.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

--- @param a Vec3
--- @param b Vec3
--- @return Vec3
function Vec3.__sub(a, b)
    return Vec3.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

--- Scales a vector; works as `v * s` and `s * v`.
--- @param a Vec3|number
--- @param b Vec3|number
--- @return Vec3
function Vec3.__mul(a, b)
    if type(a) == "number" then
        a, b = b, a
    end
    --- @cast a Vec3
    --- @cast b number
    return Vec3.new(a.x * b, a.y * b, a.z * b)
end

--- @param a Vec3
--- @param b number
--- @return Vec3
function Vec3.__div(a, b)
    return Vec3.new(a.x / b, a.y / b, a.z / b)
end

--- @param a Vec3
--- @return Vec3
function Vec3.__unm(a)
    return Vec3.new(-a.x, -a.y, -a.z)
end

--- Componentwise equality (plain `==` on tables would compare identity).
--- @param a Vec3
--- @param b Vec3
--- @return boolean
function Vec3.__eq(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

--- @param a Vec3
--- @return string
function Vec3.__tostring(a)
    return ("(%g, %g, %g)"):format(a.x, a.y, a.z)
end

--- @param other Vec3
--- @return number
function Vec3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

--- Right-handed cross product `self × other`.
--- @param other Vec3
--- @return Vec3
function Vec3:cross(other)
    return Vec3.new(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x)
end

--- @return number
function Vec3:length()
    return math.sqrt(self:dot(self))
end

--- Unit vector in the same direction; the vector must not be zero.
--- @return Vec3
function Vec3:normalized()
    local length = self:length()
    return Vec3.new(self.x / length, self.y / length, self.z / length)
end

--- Rounds each component down, e.g. to get the block containing a point.
--- @return Vec3
function Vec3:floor()
    return Vec3.new(math.floor(self.x), math.floor(self.y), math.floor(self.z))
end

--- Builds a vector from a function of the axis name, for per-axis formulas.
--- @param component fun(axis: Axis): number
--- @return Vec3
function Vec3.fromAxes(component)
    return Vec3.new(component("x"), component("y"), component("z"))
end

--- Unit vector along an axis, e.g. `unit("y")` is (0, 1, 0).
--- @param axis Axis
--- @return Vec3
function Vec3.unit(axis)
    return Vec3.fromAxes(function(other) return other == axis and 1 or 0 end)
end

--- Axis with the smallest component; on a tie, the later axis (z over y over x).
--- @return Axis
function Vec3:smallestAxis()
    local best = "x"
    for _, axis in ipairs(Vec3.AXES) do
        if self[axis] <= self[best] then
            best = axis
        end
    end
    return best
end

--- (0, 0, 0). Shared, like every vector, so never modify it.
Vec3.ZERO = Vec3.new(0, 0, 0)

return Vec3
