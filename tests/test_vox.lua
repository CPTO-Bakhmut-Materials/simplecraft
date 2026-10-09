local t = require("tests.lib")
local Vox = require("src.vox")
local VoxWriter = require("tools.vox_writer")

local MODEL = { sizeX = 3, sizeY = 4, sizeZ = 5, voxels = { 0, 1, 2, 7, 2, 3, 4, 9 } }

t.test("vox: round-trips size, voxels and palette", function()
    local vox = Vox.parse(VoxWriter.encode(MODEL, { [7] = { 10, 20, 30 } }))
    t.eq(vox.version, 150)
    t.eq(#vox.models, 1)
    local model = vox.models[1]
    t.eq(model.sizeX, 3); t.eq(model.sizeY, 4); t.eq(model.sizeZ, 5)
    t.eq(model.count, 2)
    for i, value in ipairs(MODEL.voxels) do
        t.eq(model.voxels[i], value, "voxel byte " .. i)
    end
    t.eq(vox.palette[7][1], 10); t.eq(vox.palette[7][2], 20); t.eq(vox.palette[7][3], 30)
end)

t.test("vox: palette is optional", function()
    t.eq(Vox.parse(VoxWriter.encode(MODEL, nil)).palette, nil)
end)

t.test("vox: skips unknown chunks", function()
    local data = VoxWriter.encode(MODEL, nil)
    -- Insert an unknown chunk before SIZE and grow MAIN's children size by its length.
    local extra = "nTRN" .. "\4\0\0\0" .. "\0\0\0\0" .. "abcd"
    local childrenSize = #data - 20 + #extra
    local patched = data:sub(1, 16)
        .. string.char(childrenSize % 256, math.floor(childrenSize / 256) % 256, 0, 0)
        .. extra .. data:sub(21)
    t.eq(Vox.parse(patched).models[1].count, 2)
end)

t.test("vox: rejects wrong magic", function()
    t.raises(function() Vox.parse("NOPE" .. string.rep("\0", 20)) end, "missing 'VOX ' header")
end)

t.test("vox: rejects non-string input", function()
    t.raises(function() Vox.parse(nil) end, "missing 'VOX ' header")
end)

t.test("vox: rejects truncated files", function()
    local data = VoxWriter.encode(MODEL, nil)
    t.raises(function() Vox.parse(data:sub(1, #data - 3)) end, "past end of file")
end)

t.test("vox: rejects files without models", function()
    local empty = "VOX " .. "\150\0\0\0" .. "MAIN" .. string.rep("\0", 8)
    t.raises(function() Vox.parse(empty) end, "no models")
end)
