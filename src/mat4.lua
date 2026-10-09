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

local function normalize(x, y, z)
    local length = math.sqrt(x * x + y * y + z * z)
    return x / length, y / length, z / length
end

local function cross(ax, ay, az, bx, by, bz)
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

--- View matrix for an eye at (ex, ey, ez) looking along direction (dx, dy, dz).
--- `dx, dy, dz` must not be parallel to the up vector (ux, uy, uz).
--- @param ex number
--- @param ey number
--- @param ez number
--- @param dx number
--- @param dy number
--- @param dz number
--- @param ux number
--- @param uy number
--- @param uz number
--- @return Mat4
function Mat4.lookAlong(ex, ey, ez, dx, dy, dz, ux, uy, uz)
    local zx, zy, zz = normalize(-dx, -dy, -dz)
    local xx, xy, xz = normalize(cross(ux, uy, uz, zx, zy, zz))
    local yx, yy, yz = cross(zx, zy, zz, xx, xy, xz)
    return {
        xx, xy, xz, -(xx * ex + xy * ey + xz * ez),
        yx, yy, yz, -(yx * ex + yy * ey + yz * ez),
        zx, zy, zz, -(zx * ex + zy * ey + zz * ez),
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

--- Transforms the point (x, y, z, 1); returns x, y, z, w.
--- @param m Mat4
--- @param x number
--- @param y number
--- @param z number
--- @return number, number, number, number
function Mat4.transformPoint(m, x, y, z)
    return m[1] * x + m[2] * y + m[3] * z + m[4],
        m[5] * x + m[6] * y + m[7] * z + m[8],
        m[9] * x + m[10] * y + m[11] * z + m[12],
        m[13] * x + m[14] * y + m[15] * z + m[16]
end

return Mat4
