--- Voxel ray traversal (Amanatides & Woo, "A Fast Voxel Traversal Algorithm").

local Vec3 = require("src.math.vec3")

--- @class RaycastHit
--- @field block Vec3 Integer coordinates of the block that was hit.
--- @field normal Vec3 Normal of the face the ray entered through; zero if the
---   ray started inside a solid block.

local Raycast = {}

local function axisSetup(origin, direction)
    local cell = math.floor(origin)
    if direction > 0 then
        return cell, 1, (cell + 1 - origin) / direction, 1 / direction
    elseif direction < 0 then
        return cell, -1, (origin - cell) / -direction, -1 / direction
    end
    return cell, 0, math.huge, math.huge
end

--- Finds the first solid block along a ray.
--- @param isSolid fun(x: integer, y: integer, z: integer): boolean
--- @param origin Vec3
--- @param direction Vec3 Must be normalized so `maxDistance` is in blocks.
--- @param maxDistance number
--- @return RaycastHit? hit nil if nothing solid is within `maxDistance`.
function Raycast.cast(isSolid, origin, direction, maxDistance)
    local x, stepX, tMaxX, tDeltaX = axisSetup(origin.x, direction.x)
    local y, stepY, tMaxY, tDeltaY = axisSetup(origin.y, direction.y)
    local z, stepZ, tMaxZ, tDeltaZ = axisSetup(origin.z, direction.z)
    local nx, ny, nz = 0, 0, 0
    local distance = 0

    while distance <= maxDistance do
        if isSolid(x, y, z) then
            return { block = Vec3.new(x, y, z), normal = Vec3.new(nx, ny, nz) }
        end
        if tMaxX < tMaxY and tMaxX < tMaxZ then
            x, distance, tMaxX = x + stepX, tMaxX, tMaxX + tDeltaX
            nx, ny, nz = -stepX, 0, 0
        elseif tMaxY < tMaxZ then
            y, distance, tMaxY = y + stepY, tMaxY, tMaxY + tDeltaY
            nx, ny, nz = 0, -stepY, 0
        else
            z, distance, tMaxZ = z + stepZ, tMaxZ, tMaxZ + tDeltaZ
            nx, ny, nz = 0, 0, -stepZ
        end
    end
    return nil
end

return Raycast
