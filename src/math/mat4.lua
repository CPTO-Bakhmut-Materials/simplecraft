--- 4x4 matrix.
--
-- Stored as 16 numbers in row-major order (send to shaders with the "row"
-- layout). Conventions follow OpenGL: right-handed view space looking down -Z,
-- clip-space depth in [-1, 1]. Immutable, like Vec3: `a * b` returns a new matrix.

local Vec3 = require("src.math.vec3")

--- @class Mat4
--- @field [integer] number Element (row, col) is at index (row - 1) * 4 + col.
--- @operator mul(Mat4): Mat4
local Mat4 = {}
Mat4.__index = Mat4

--- @param values number[] 16 numbers, row-major.
--- @return Mat4
function Mat4.new(values)
    assert(#values == 16, "a 4x4 matrix needs 16 values")
    return setmetatable(values, Mat4)
end

--- @param fovY number Vertical field of view in radians.
--- @param aspect number Width / height.
--- @param near number
--- @param far number
--- @return Mat4
function Mat4.perspective(fovY, aspect, near, far)
    local f = 1 / math.tan(fovY / 2)
    return Mat4.new({
        f / aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (far + near) / (near - far), 2 * far * near / (near - far),
        0, 0, -1, 0,
    })
end

--- View matrix for an eye at `eye` looking along `direction`, which must not
--- be parallel to `up`.
--- @param eye Vec3
--- @param direction Vec3
--- @param up Vec3
--- @return Mat4
function Mat4.lookAlong(eye, direction, up)
    local zAxis = (-direction):normalized()
    local xAxis = up:cross(zAxis):normalized()
    local yAxis = zAxis:cross(xAxis)
    return Mat4.new({
        xAxis.x, xAxis.y, xAxis.z, -xAxis:dot(eye),
        yAxis.x, yAxis.y, yAxis.z, -yAxis:dot(eye),
        zAxis.x, zAxis.y, zAxis.z, -zAxis:dot(eye),
        0, 0, 0, 1,
    })
end

--- @param row integer 1..4
--- @param col integer 1..4
--- @return number
function Mat4:get(row, col)
    return self[(row - 1) * 4 + col]
end

--- Matrix product `a * b` (applies `b` first, then `a`).
--- @param a Mat4
--- @param b Mat4
--- @return Mat4
function Mat4.__mul(a, b)
    local values = {}
    for row = 1, 4 do
        for col = 1, 4 do
            local sum = 0
            for k = 1, 4 do
                sum = sum + a:get(row, k) * b:get(k, col)
            end
            values[#values + 1] = sum
        end
    end
    return Mat4.new(values)
end

--- Transforms a point and divides by w, e.g. from world space to normalized
--- device coordinates through a view-projection matrix.
--- @param point Vec3
--- @return Vec3
function Mat4:transformPoint(point)
    local homogeneous = { point.x, point.y, point.z, 1 }
    local function row(r)
        local sum = 0
        for col = 1, 4 do
            sum = sum + self:get(r, col) * homogeneous[col]
        end
        return sum
    end
    return Vec3.new(row(1), row(2), row(3)) / row(4)
end

return Mat4
