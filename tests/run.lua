--- Runs the unit tests. From the project root: `luajit tests/run.lua`

local lib = require("tests.lib")

local SUITES = {
    "vec3", "extent3", "mat4", "vox", "world", "mesher", "raycast", "camera", "touch_controls", "input_toggle",
}

for _, name in ipairs(SUITES) do
    require("tests.test_" .. name)
end

os.exit(lib.run() == 0 and 0 or 1)
