--- Minimal 4x4 matrix helpers.
-- Matrices are flat, row-major arrays of 16 numbers (send to shaders with the
-- "row" layout). Conventions follow OpenGL: right-handed view space looking
-- down -Z, clip-space depth in [-1, 1].

--- @alias Mat4 number[] 16 numbers, row-major.

local Mat4 = {}

--- @param fovY number Vertical field of view in radians.
--- @param aspect number Width / height.
--- @param near number
--- @param far number
--- @return Mat4
function Mat4.perspective(fovY, aspect, near, far)
    local f = 1 / math.tan(fovY / 2)
    return {
        f / aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (far + near) / (near - far), 2 * far * near / (near - far),
        0, 0, -1, 0,
    }
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
    return {
        xAxis.x, xAxis.y, xAxis.z, -xAxis:dot(eye),
        yAxis.x, yAxis.y, yAxis.z, -yAxis:dot(eye),
        zAxis.x, zAxis.y, zAxis.z, -zAxis:dot(eye),
        0, 0, 0, 1,
    }
end

--- Returns a * b.
--- @param a Mat4
--- @param b Mat4
--- @return Mat4
function Mat4.multiply(a, b)
    local out = {}
    for row = 0, 3 do
        for col = 1, 4 do
            local sum = 0
            for k = 1, 4 do
                sum = sum + a[row * 4 + k] * b[(k - 1) * 4 + col]
            end
            out[row * 4 + col] = sum
        end
    end
    return out
end

--- Transforms the point (p.x, p.y, p.z, 1); returns homogeneous x, y, z, w.
--- @param m Mat4
--- @param p Vec3
--- @return number x, number y, number z, number w
function Mat4.transformPoint(m, p)
    local x, y, z = p.x, p.y, p.z
    return m[1] * x + m[2] * y + m[3] * z + m[4],
        m[5] * x + m[6] * y + m[7] * z + m[8],
        m[9] * x + m[10] * y + m[11] * z + m[12],
        m[13] * x + m[14] * y + m[15] * z + m[16]
end

return Mat4
