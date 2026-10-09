--- Loads a world from a MagicaVoxel .vox file: reads it, parses it (see
--- src/world/vox.lua) and turns the first model into a World, mapping each voxel's
--- color to the block type with the nearest reference color (Blocks.fromColor).

local Blocks = require("src.world.blocks")
local Vox = require("src.world.vox")
local World = require("src.world.world")

local WorldLoader = {}

--- Reads a file from the game directory, falling back to the OS filesystem so
--- worlds outside the project can be passed on the command line.
--- @param path string
--- @return string
local function readFile(path)
    if love.filesystem.getInfo(path, "file") then
        return assert(love.filesystem.read(path))
    end
    local file, err = io.open(path, "rb")
    if not file then
        error(("cannot open world file: %s"):format(err), 0)
    end
    local data = file:read("*a")
    file:close()
    return data
end

--- Builds a world from a parsed .vox file, using its first model.
--- @param vox VoxFile
--- @return World
function WorldLoader.fromVox(vox)
    if not vox.palette then
        error("world file has no color palette (RGBA chunk)", 0)
    end
    local blockForIndex = {}
    for index, color in ipairs(vox.palette) do
        blockForIndex[index] = Blocks.fromColor(color[1], color[2], color[3])
    end

    local model = vox.models[1]
    local world = World.new(model.size)
    for _, voxel in ipairs(model.voxels) do
        world:set(voxel.position, blockForIndex[voxel.colorIndex] or Blocks.STONE)
    end
    return world
end

--- Loads the world in a .vox file. Errors with a readable message on failure.
--- @param path string
--- @return World
function WorldLoader.load(path)
    local ok, result = pcall(function()
        local vox = Vox.parse(readFile(path))
        if #vox.models > 1 then
            print(("warning: '%s' has %d models; only the first is loaded"):format(path, #vox.models))
        end
        return WorldLoader.fromVox(vox)
    end)
    if not ok then
        error(("Failed to load world '%s':\n%s"):format(path, result), 0)
    end
    return result
end

return WorldLoader
