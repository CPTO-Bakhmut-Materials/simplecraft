--- Builds triangle lists for world chunks.
--
-- Only faces between a solid block and air are emitted. Each vertex is
-- `{ x, y, z, u, v, layer, shade, shade, shade, 1 }`, matching the mesh
-- format in src/render/renderer.lua. Triangles are wound counter-clockwise when seen
-- from outside the block, so back-face culling can be enabled.

local Blocks = require("src.world.blocks")
local Vec3 = require("src.math.vec3")

--- @alias MeshVertex number[] `{ x, y, z, u, v, layer, r, g, b, a }`

--- @class CubeFace
--- @field normal Vec3 Points out of the block; the neighbor across this face is `block + normal`.
--- @field texture BlockFace Which of the block's textures the face uses.
--- @field shade number Brightness, faking directional light.
--- @field corners Vec3[] Offsets from the block's minimum corner.

local Mesher = {}

-- Corners are listed counter-clockwise as seen from outside, starting at the
-- bottom-left of the texture.
--- @type CubeFace[]
local FACES = {
    {
        normal = Vec3.new(1, 0, 0), texture = "side", shade = 0.8,
        corners = { Vec3.new(1, 0, 0), Vec3.new(1, 1, 0), Vec3.new(1, 1, 1), Vec3.new(1, 0, 1) },
    },
    {
        normal = Vec3.new(-1, 0, 0), texture = "side", shade = 0.8,
        corners = { Vec3.new(0, 1, 0), Vec3.new(0, 0, 0), Vec3.new(0, 0, 1), Vec3.new(0, 1, 1) },
    },
    {
        normal = Vec3.new(0, 1, 0), texture = "side", shade = 0.65,
        corners = { Vec3.new(1, 1, 0), Vec3.new(0, 1, 0), Vec3.new(0, 1, 1), Vec3.new(1, 1, 1) },
    },
    {
        normal = Vec3.new(0, -1, 0), texture = "side", shade = 0.65,
        corners = { Vec3.new(0, 0, 0), Vec3.new(1, 0, 0), Vec3.new(1, 0, 1), Vec3.new(0, 0, 1) },
    },
    {
        normal = Vec3.new(0, 0, 1), texture = "top", shade = 1.0,
        corners = { Vec3.new(0, 0, 1), Vec3.new(1, 0, 1), Vec3.new(1, 1, 1), Vec3.new(0, 1, 1) },
    },
    {
        normal = Vec3.new(0, 0, -1), texture = "bottom", shade = 0.5,
        corners = { Vec3.new(0, 1, 0), Vec3.new(1, 1, 0), Vec3.new(1, 0, 0), Vec3.new(0, 0, 0) },
    },
}

-- Texture coordinates for corners 1..4 (bottom-left, bottom-right, top-right, top-left).
local CORNER_UV = { { 0, 1 }, { 1, 1 }, { 1, 0 }, { 0, 0 } }

-- Two triangles per quad, preserving the corner winding.
local QUAD_ORDER = { 1, 2, 3, 1, 3, 4 }

--- @param vertices MeshVertex[] Appended to.
--- @param block Vec3
--- @param face CubeFace
--- @param layer integer Texture layer.
local function emitFace(vertices, block, face, layer)
    local shade = face.shade
    for _, cornerIndex in ipairs(QUAD_ORDER) do
        local position, uv = block + face.corners[cornerIndex], CORNER_UV[cornerIndex]
        vertices[#vertices + 1] = {
            position.x, position.y, position.z,
            uv[1], uv[2], layer,
            shade, shade, shade, 1,
        }
    end
end

--- Returns the vertex list for the cube of blocks starting at `origin` with
--- edge length `size`, clipped to the world. May be empty.
--- @param world World
--- @param origin Vec3 Minimum corner, in blocks.
--- @param size integer
--- @return MeshVertex[]
function Mesher.buildChunk(world, origin, size)
    local vertices = {}
    local last = Vec3.fromAxes(function(axis) return math.min(origin[axis] + size, world.size[axis]) - 1 end)

    for z = origin.z, last.z do
        for y = origin.y, last.y do
            for x = origin.x, last.x do
                local block = Vec3.new(x, y, z)
                local id = world:get(block)
                if id ~= Blocks.AIR then
                    for _, face in ipairs(FACES) do
                        if not world:isSolid(block + face.normal) then
                            emitFace(vertices, block, face, Blocks.textureLayer(id, face.texture))
                        end
                    end
                end
            end
        end
    end
    return vertices
end

return Mesher
