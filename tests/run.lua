--- Runs the unit tests. From the project root: `luajit tests/run.lua`

local lib = require("tests.lib")

for _, name in ipairs({ "vec3", "extent3", "mat4", "vox", "world", "mesher", "raycast", "camera" }) do
    require("tests.test_" .. name)
end

os.exit(lib.run() == 0 and 0 or 1)
