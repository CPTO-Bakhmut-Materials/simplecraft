--- The crosshair in the middle of the screen, marking the block that break and
--- place act on.

local Crosshair = {}

local SIZE = 0.012 -- half the line length, as a fraction of the shorter screen side

--- Draws the crosshair over the current frame.
function Crosshair.draw()
    local graphics = love.graphics
    local width, height = graphics.getDimensions()
    local cx, cy, size = width / 2, height / 2, math.max(8, SIZE * math.min(width, height))
    graphics.push("all")
    graphics.setLineWidth(2)
    graphics.setColor(1, 1, 1, 0.9)
    graphics.line(cx - size, cy, cx + size, cy)
    graphics.line(cx, cy - size, cx, cy + size)
    graphics.pop()
end

return Crosshair
