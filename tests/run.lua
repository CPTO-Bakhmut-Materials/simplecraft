--- Runs the unit tests. From the project root: `luajit tests/run.lua`

local lib = require("tests.lib")

for _, name in ipairs({ "vox", "world", "mesher", "raycast", "mat4", "camera" }) do
    require("tests.test_" .. name)
end

os.exit(lib.run() == 0 and 0 or 1)
