--- Runs the unit tests. From the project root: `luajit tests/run.lua`

-- Let `require("src.input")` find src/input/init.lua, as LÖVE does.
package.path = "./?/init.lua;" .. package.path

local lib = require("tests.lib")

local SUITES = {
    "vec3", "extent3", "mat4",
    "vox", "world", "world_load", "raycast",
    "camera", "mesher", "renderer",
    "touch_layout", "touch", "mouse_keyboard", "input",
    "game",
}

for _, name in ipairs(SUITES) do
    require("tests.test_" .. name)
end

os.exit(lib.run() == 0 and 0 or 1)
