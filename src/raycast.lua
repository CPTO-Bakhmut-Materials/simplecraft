--- Voxel ray traversal (Amanatides & Woo, "A Fast Voxel Traversal Algorithm").

--- @class RaycastHit
--- @field x integer Block that was hit.
--- @field y integer
--- @field z integer
--- @field nx integer Normal of the face the ray entered through; all 0 if the
---   ray started inside a solid block.
--- @field ny integer
--- @field nz integer

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
--- @param ox number Ray origin.
--- @param oy number
--- @param oz number
--- @param dx number Ray direction; must be normalized so `maxDistance` is in blocks.
--- @param dy number
--- @param dz number
--- @param maxDistance number
--- @return RaycastHit? hit nil if nothing solid is within `maxDistance`.
function Raycast.cast(isSolid, ox, oy, oz, dx, dy, dz, maxDistance)
    local x, stepX, tMaxX, tDeltaX = axisSetup(ox, dx)
    local y, stepY, tMaxY, tDeltaY = axisSetup(oy, dy)
    local z, stepZ, tMaxZ, tDeltaZ = axisSetup(oz, dz)
    local nx, ny, nz = 0, 0, 0
    local distance = 0

    while distance <= maxDistance do
        if isSolid(x, y, z) then
            return { x = x, y = y, z = z, nx = nx, ny = ny, nz = nz }
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
