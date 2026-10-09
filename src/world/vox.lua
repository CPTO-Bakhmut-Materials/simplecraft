--- Parser for the MagicaVoxel .vox format.
-- Spec: https://github.com/ephtracy/voxel-model/blob/master/MagicaVoxel-file-format-vox.txt
--
-- Only the chunks needed for a static block world are read: SIZE, XYZI and
-- RGBA. Scene graph, material and layer chunks are skipped. Pure Lua, no LÖVE
-- dependency, so it can be unit tested outside the engine.

--- @class Voxel
--- @field position Vec3 0-based integer coordinates.
--- @field colorIndex integer Palette index, 1..255.

--- @class VoxModel
--- @field size Extent3
--- @field voxels Voxel[]

--- @class VoxFile
--- @field version integer
--- @field models VoxModel[] At least one.
--- @field palette integer[][]? Color index (1..255) -> `{ r, g, b, a }`; nil without an RGBA chunk.

local Extent3 = require("src.math.extent3")
local Vec3 = require("src.math.vec3")

local Vox = {}

local HEADER_SIZE = 12 -- chunk id (4) + content size (4) + children size (4)

local function fail(message, ...)
    error("vox: " .. message:format(...), 0)
end

local function readU32(data, pos)
    local b1, b2, b3, b4 = data:byte(pos, pos + 3)
    if not b4 then
        fail("unexpected end of file at offset %d", pos - 1)
    end
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000
end

local function readChunkHeader(data, pos)
    if pos + HEADER_SIZE - 1 > #data then
        fail("truncated chunk header at offset %d", pos - 1)
    end
    local id = data:sub(pos, pos + 3)
    local contentSize = readU32(data, pos + 4)
    local childrenSize = readU32(data, pos + 8)
    if pos + HEADER_SIZE + contentSize + childrenSize - 1 > #data then
        fail("chunk '%s' at offset %d extends past end of file", id, pos - 1)
    end
    return id, contentSize, childrenSize
end

local function readVoxels(data, pos, contentSize)
    local count = readU32(data, pos)
    if 4 + count * 4 > contentSize then
        fail("XYZI chunk declares %d voxels but holds only %d bytes", count, contentSize)
    end
    local voxels = {}
    for i = 0, count - 1 do
        local p = pos + 4 + i * 4
        local x, y, z, colorIndex = data:byte(p, p + 3)
        voxels[#voxels + 1] = { position = Vec3.new(x, y, z), colorIndex = colorIndex }
    end
    return voxels
end

local function readPalette(data, pos)
    -- Entry i of the chunk (0-based) is the color of palette index i + 1.
    local palette = {}
    for index = 1, 255 do
        local r, g, b, a = data:byte(pos + (index - 1) * 4, pos + (index - 1) * 4 + 3)
        palette[index] = { r, g, b, a }
    end
    return palette
end

--- Parses the contents of a .vox file. Errors on malformed input.
--- @param data string Raw file bytes.
--- @return VoxFile
function Vox.parse(data)
    if type(data) ~= "string" or #data < 8 or data:sub(1, 4) ~= "VOX " then
        fail("not a MagicaVoxel file (missing 'VOX ' header)")
    end
    local version = readU32(data, 5)

    local id, contentSize, childrenSize = readChunkHeader(data, 9)
    if id ~= "MAIN" then
        fail("expected MAIN chunk, found '%s'", id)
    end

    local pos = 9 + HEADER_SIZE + contentSize
    local finish = pos + childrenSize
    local models, palette, pendingSize = {}, nil, nil

    while pos < finish do
        id, contentSize, childrenSize = readChunkHeader(data, pos)
        local body = pos + HEADER_SIZE
        if id == "SIZE" then
            pendingSize = Extent3.new(readU32(data, body), readU32(data, body + 4), readU32(data, body + 8))
        elseif id == "XYZI" then
            if not pendingSize then
                fail("XYZI chunk at offset %d has no preceding SIZE chunk", pos - 1)
            end
            --- @cast pendingSize -nil
            models[#models + 1] = { size = pendingSize, voxels = readVoxels(data, body, contentSize) }
            pendingSize = nil
        elseif id == "RGBA" then
            if contentSize < 255 * 4 then
                fail("RGBA chunk is too small (%d bytes)", contentSize)
            end
            palette = readPalette(data, body)
        end
        pos = body + contentSize + childrenSize
    end

    if #models == 0 then
        fail("file contains no models")
    end
    return { version = version, models = models, palette = palette }
end

return Vox
