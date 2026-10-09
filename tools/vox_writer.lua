--- Encodes a single-model MagicaVoxel .vox file (version 150).
-- Used by tools/make_test_world.lua and the tests; the game never writes worlds.

local VoxWriter = {}

local function u32(n)
    return string.char(n % 0x100, math.floor(n / 0x100) % 0x100,
        math.floor(n / 0x10000) % 0x100, math.floor(n / 0x1000000) % 0x100)
end

local function chunk(id, content)
    return id .. u32(#content) .. u32(0) .. content
end

--- @param model table `{ sizeX, sizeY, sizeZ, voxels = { x, y, z, colorIndex, ... } }`
-- @param palette table|nil Map of color index (1..255) -> `{ r, g, b }`; omitted
--   entries are black. Pass nil to write a file without an RGBA chunk.
-- @return string File contents.
function VoxWriter.encode(model, palette)
    local voxelBytes = {}
    for i = 1, #model.voxels, 4 do
        local v = model.voxels
        voxelBytes[#voxelBytes + 1] = string.char(v[i], v[i + 1], v[i + 2], v[i + 3])
    end

    local children = chunk("SIZE", u32(model.sizeX) .. u32(model.sizeY) .. u32(model.sizeZ))
        .. chunk("XYZI", u32(#model.voxels / 4) .. table.concat(voxelBytes))

    if palette then
        local entries = {}
        for index = 1, 256 do
            local color = palette[index] or { 0, 0, 0 }
            entries[index] = string.char(color[1], color[2], color[3], 255)
        end
        children = children .. chunk("RGBA", table.concat(entries))
    end

    return "VOX " .. u32(150) .. "MAIN" .. u32(0) .. u32(#children) .. children
end

return VoxWriter
