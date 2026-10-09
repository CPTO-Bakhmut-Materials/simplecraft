--- Builds triangle lists for world chunks.
--
-- Only faces between a solid block and air are emitted. Each vertex is
-- `{ x, y, z, u, v, layer, shade, shade, shade, 1 }`, matching the mesh
-- format in src/renderer.lua. Triangles are wound counter-clockwise when seen
-- from outside the block, so back-face culling can be enabled.

local Blocks = require("src.blocks")

local Mesher = {}

-- Corners are listed counter-clockwise as seen from outside, starting at the
-- bottom-left of the texture. `shade` fakes directional light.
local FACES = {
    { -- +X
        dx = 1, dy = 0, dz = 0, texture = "side", shade = 0.8,
        corners = { { 1, 0, 0 }, { 1, 1, 0 }, { 1, 1, 1 }, { 1, 0, 1 } },
    },
    { -- -X
        dx = -1, dy = 0, dz = 0, texture = "side", shade = 0.8,
        corners = { { 0, 1, 0 }, { 0, 0, 0 }, { 0, 0, 1 }, { 0, 1, 1 } },
    },
    { -- +Y
        dx = 0, dy = 1, dz = 0, texture = "side", shade = 0.65,
        corners = { { 1, 1, 0 }, { 0, 1, 0 }, { 0, 1, 1 }, { 1, 1, 1 } },
    },
    { -- -Y
        dx = 0, dy = -1, dz = 0, texture = "side", shade = 0.65,
        corners = { { 0, 0, 0 }, { 1, 0, 0 }, { 1, 0, 1 }, { 0, 0, 1 } },
    },
    { -- +Z (top)
        dx = 0, dy = 0, dz = 1, texture = "top", shade = 1.0,
        corners = { { 0, 0, 1 }, { 1, 0, 1 }, { 1, 1, 1 }, { 0, 1, 1 } },
    },
    { -- -Z (bottom)
        dx = 0, dy = 0, dz = -1, texture = "bottom", shade = 0.5,
        corners = { { 0, 1, 0 }, { 1, 1, 0 }, { 1, 0, 0 }, { 0, 0, 0 } },
    },
}

-- Texture coordinates for corners 1..4 (bottom-left, bottom-right, top-right, top-left).
local CORNER_UV = { { 0, 1 }, { 1, 1 }, { 1, 0 }, { 0, 0 } }

-- Two triangles per quad, preserving the corner winding.
local QUAD_ORDER = { 1, 2, 3, 1, 3, 4 }

local function emitFace(vertices, x, y, z, face, layer)
    local shade = face.shade
    for _, cornerIndex in ipairs(QUAD_ORDER) do
        local corner, uv = face.corners[cornerIndex], CORNER_UV[cornerIndex]
        vertices[#vertices + 1] = {
            x + corner[1], y + corner[2], z + corner[3],
            uv[1], uv[2], layer,
            shade, shade, shade, 1,
        }
    end
end

--- Returns the vertex list for the cube of blocks starting at (x0, y0, z0)
-- with edge length `size`, clipped to the world. May be empty.
function Mesher.buildChunk(world, x0, y0, z0, size)
    local vertices = {}
    local x1 = math.min(x0 + size, world.sizeX) - 1
    local y1 = math.min(y0 + size, world.sizeY) - 1
    local z1 = math.min(z0 + size, world.sizeZ) - 1

    for z = z0, z1 do
        for y = y0, y1 do
            for x = x0, x1 do
                local id = world:get(x, y, z)
                if id ~= Blocks.AIR then
                    local def = Blocks.defs[id]
                    for _, face in ipairs(FACES) do
                        if not world:isSolid(x + face.dx, y + face.dy, z + face.dz) then
                            emitFace(vertices, x, y, z, face, def[face.texture])
                        end
                    end
                end
            end
        end
    end
    return vertices
end

return Mesher
