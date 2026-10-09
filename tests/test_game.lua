local t = require("tests.lib")
local Blocks = require("src.world.blocks")
local Camera = require("src.render.camera")
local Extent3 = require("src.math.extent3")
local Game = require("src.game")
local Vec3 = require("src.math.vec3")
local World = require("src.world.world")

local FLOOR = Vec3.new(1, 1, 0) -- the one stone block in the test world

--- A 3x3x3 world with stone at FLOOR.
--- @return World
local function newWorld()
    local world = World.new(Extent3.new(3, 3, 3))
    world:set(FLOOR, Blocks.STONE)
    return world
end

--- A camera at `position` looking (almost) straight down.
--- @param position Vec3
--- @return Camera
local function lookingDown(position)
    return Camera.new({ position = position, pitch = -math.pi / 2, fov = 1, near = 0.1, far = 100 })
end

t.test("game: break clears the block at the crosshair", function()
    local edit = assert(Game.chooseEdit(newWorld(), lookingDown(Vec3.new(1.5, 1.5, 2.5)), "break"))
    t.eq(edit.block, FLOOR); t.eq(edit.id, Blocks.AIR)
end)

t.test("game: place puts dirt against the face at the crosshair", function()
    local edit = assert(Game.chooseEdit(newWorld(), lookingDown(Vec3.new(1.5, 1.5, 2.5)), "place"))
    t.eq(edit.block, FLOOR + Vec3.new(0, 0, 1)); t.eq(edit.id, Blocks.DIRT)
end)

t.test("game: nothing in reach means no edit", function()
    local camera = lookingDown(Vec3.new(1.5, 1.5, 2.5))
    local empty = World.new(Extent3.new(3, 3, 3))
    t.eq(Game.chooseEdit(empty, camera, "break"), nil)
    t.eq(Game.chooseEdit(empty, camera, "place"), nil)
end)

t.test("game: inside a block, break clears it but place has no face to build on", function()
    local world = newWorld()
    local camera = lookingDown(Vec3.new(1.5, 1.5, 0.5)) -- inside FLOOR
    local edit = assert(Game.chooseEdit(world, camera, "break"))
    t.eq(edit.block, FLOOR)
    t.eq(Game.chooseEdit(world, camera, "place"), nil)
end)

t.test("game: place never builds a block around the camera", function()
    local camera = lookingDown(Vec3.new(1.5, 1.5, 1.5)) -- right above FLOOR, in the block place would fill
    t.eq(Game.chooseEdit(newWorld(), camera, "place"), nil)
end)
