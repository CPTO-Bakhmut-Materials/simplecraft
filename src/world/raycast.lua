--- Voxel ray traversal (Amanatides & Woo, "A Fast Voxel Traversal Algorithm").
--
-- The ray visits blocks in order: on each step it crosses into the next block
-- along whichever axis has the nearest block boundary.

local Vec3 = require("src.math.vec3")

--- @class RaycastHit
--- @field block Vec3 Integer coordinates of the block that was hit.
--- @field normal Vec3 Normal of the face the ray entered through; zero if the
---   ray started inside a solid block.

local Raycast = {}

--- @param value number
--- @return integer -1, 0 or 1
local function sign(value)
    return value > 0 and 1 or (value < 0 and -1 or 0)
end

--- Finds the first solid block along a ray.
--- @param isSolid fun(block: Vec3): boolean
--- @param origin Vec3
--- @param direction Vec3 Must be normalized so `maxDistance` is in blocks.
--- @param maxDistance number
--- @return RaycastHit? hit nil if nothing solid is within `maxDistance`.
function Raycast.cast(isSolid, origin, direction, maxDistance)
    local block = origin:floor()
    -- Which way the ray moves through the grid on each axis.
    local step = Vec3.fromAxes(function(axis) return sign(direction[axis]) end)
    -- Ray distance between two block boundaries on each axis (infinite if the
    -- ray is parallel to that axis's boundaries).
    local boundarySpacing = Vec3.fromAxes(function(axis) return math.abs(1 / direction[axis]) end)
    -- Ray distance to the next block boundary on each axis.
    local nextBoundary = Vec3.fromAxes(function(axis)
        if step[axis] == 0 then
            return math.huge
        end
        local boundary = block[axis] + (step[axis] > 0 and 1 or 0)
        return (boundary - origin[axis]) / direction[axis]
    end)

    local normal = Vec3.ZERO
    local distance = 0
    while distance <= maxDistance do
        if isSolid(block) then
            return { block = block, normal = normal }
        end
        local axis = nextBoundary:smallestAxis()
        distance = nextBoundary[axis]
        block = block + Vec3.unit(axis) * step[axis]
        normal = Vec3.unit(axis) * -step[axis] -- the entered face points back against the step
        nextBoundary = nextBoundary + Vec3.unit(axis) * boundarySpacing[axis]
    end
    return nil
end

return Raycast
