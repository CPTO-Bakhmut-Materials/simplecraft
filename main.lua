--- Entry point: parses the command line and hands LÖVE's frame callbacks to the
--- game (src/game.lua). Input callbacks are registered by src/input/.
-- Usage: `love . [path/to/world.vox] [--touch]`
-- `--touch` uses the on-screen touch controls instead of mouse & keyboard (the
-- web page passes it on phones and tablets).

local Config = require("src.config")
local Game = require("src.game")

local game --- @type Game

--- @param args string[] Command-line arguments after the game path.
--- @return string worldPath
--- @return boolean touchMode
local function parseArgs(args)
    local worldPath, touchMode = Config.worldPath, false
    for _, value in ipairs(args) do
        if value == "--touch" then
            touchMode = true
        elseif value:sub(1, 2) == "--" then
            error(("unknown option '%s'\nUsage: love . [path/to/world.vox] [--touch]"):format(value), 0)
        else
            worldPath = value
        end
    end
    return worldPath, touchMode
end

function love.load(args)
    game = Game.new(parseArgs(args))
    love.graphics.setBackgroundColor(Config.skyColor)
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end
