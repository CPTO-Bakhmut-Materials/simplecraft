--- Everything drawn over the world: the crosshair and, in touch mode, the
--- move keys (bottom-left) and buttons (bottom-right).
--
-- The HUD owns the on-screen layout: Hud:resize places every element for the
-- current screen and Hud:hitTest tells what is under a point. Sizes are
-- fractions of the shorter screen side ("unit"), so the layout fits any
-- resolution. Everything except Hud:draw is plain Lua, so it can be unit tested.
--
-- Labels are drawn shapes, not text, so the HUD does not depend on fonts.

--- @alias HudButtonName "forward"|"back"|"left"|"right"|"up"|"down"|BlockAction

--- @class HudButton
--- @field name HudButtonName
--- @field kind "move"|"fly"|"action" Move keys are squares (bottom-left), the rest circles (bottom-right).
--- @field action BlockAction? What an "action" button does.
--- @field x number Center, in pixels.
--- @field y number
--- @field size number Half the side of a square, radius of a circle.

--- @class Hud
--- @field width number Screen size the layout was computed for.
--- @field height number
--- @field unit number Shorter screen side; all sizes are fractions of it.
--- @field keyGap number Space between direction keys, in pixels.
--- @field buttons HudButton[] Direction keys and buttons.
local Hud = {}
Hud.__index = Hud

-- Fractions of `unit`.
local MARGIN = 0.05 -- from the screen edges
local KEY_SIZE = 0.12 -- side of a direction key
local KEY_GAP = 0.015
local BUTTON_RADIUS = 0.075
local CROSSHAIR_SIZE = 0.012

local BUTTON_SPACING = 2.4 -- distance between button centers, in button radii
local BUTTON_HIT_SCALE = 1.2 -- buttons accept touches slightly outside their circle

--- @return Hud
function Hud.new()
    local self = setmetatable({}, Hud)
    self:resize(0, 0)
    return self
end

--- Lays every element out for a screen of the given size. Cheap to call every
--- frame: it does nothing unless the size changed.
--- @param width number
--- @param height number
function Hud:resize(width, height)
    if width == self.width and height == self.height then
        return
    end
    local unit = math.min(width, height)
    local margin = MARGIN * unit
    self.width, self.height, self.unit = width, height, unit

    -- Direction keys in a plus shape in the bottom-left corner, around an empty center.
    local key, gap = KEY_SIZE * unit, KEY_GAP * unit
    local keyStep = key + gap
    local padX, padY = margin + key * 1.5 + gap, height - margin - key * 1.5 - gap
    local function moveKey(name, column, row)
        return { name = name, kind = "move", x = padX + column * keyStep, y = padY + row * keyStep, size = key / 2 }
    end
    self.keyGap = gap

    -- 2x2 grid in the bottom-right corner: fly buttons above the action buttons.
    local radius = BUTTON_RADIUS * unit
    local right, bottom = width - margin - radius, height - margin - radius
    local step = BUTTON_SPACING * radius
    local function flyButton(name, x, y)
        return { name = name, kind = "fly", x = x, y = y, size = radius }
    end
    --- @param action BlockAction
    --- @param x number
    --- @param y number
    --- @return HudButton
    local function actionButton(action, x, y)
        return { name = action, kind = "action", action = action, x = x, y = y, size = radius }
    end

    self.buttons = {
        moveKey("forward", 0, -1), moveKey("back", 0, 1), moveKey("left", -1, 0), moveKey("right", 1, 0),
        flyButton("up", right, bottom - step), flyButton("down", right - step, bottom - step),
        actionButton("place", right, bottom), actionButton("break", right - step, bottom),
    }
end

--- The touch button under a screen point, or nil.
--- @param x number
--- @param y number
--- @return HudButton?
function Hud:hitTest(x, y)
    for _, button in ipairs(self.buttons) do
        local dx, dy = x - button.x, y - button.y
        if button.kind == "move" then
            -- Up to half the gap: neighboring keys meet but never overlap.
            local reach = button.size + self.keyGap / 2
            if math.abs(dx) <= reach and math.abs(dy) <= reach then
                return button
            end
        else
            local reach = button.size * BUTTON_HIT_SCALE
            if dx * dx + dy * dy <= reach * reach then
                return button
            end
        end
    end
    return nil
end

-- Drawing (needs LÖVE) --------------------------------------------------------

--- Filled triangle centered on (x, y) with half-size `s`, pointing along (dx, dy).
--- @param x number
--- @param y number
--- @param s number
--- @param dx number Unit direction in screen space (y points down).
--- @param dy number
local function drawArrow(x, y, s, dx, dy)
    local tipX, tipY = x + dx * s, y + dy * s
    local baseX, baseY = x - dx * s * 0.7, y - dy * s * 0.7
    love.graphics.polygon("fill", tipX, tipY, baseX - dy * s, baseY + dx * s, baseX + dy * s, baseY - dx * s)
end

-- Screen direction of each direction key's arrow.
local ARROWS = { forward = { 0, -1 }, back = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }

--- Button icon centered on (x, y) with half-size `s`: an arrow for each direction
--- key, double arrows for flying up/down, a cross for break, a block (square)
--- for place.
--- @param name HudButtonName
--- @param x number
--- @param y number
--- @param s number
local function drawButtonIcon(name, x, y, s)
    local graphics = love.graphics
    local arrow = ARROWS[name]
    if arrow then
        drawArrow(x, y, s, arrow[1], arrow[2])
    elseif name == "up" or name == "down" then
        local dy = name == "up" and -1 or 1
        drawArrow(x, y + dy * s * 0.6, s * 0.55, 0, dy)
        drawArrow(x, y - dy * s * 0.6, s * 0.55, 0, dy)
    elseif name == "break" then
        graphics.line(x - s, y - s, x + s, y + s)
        graphics.line(x - s, y + s, x + s, y - s)
    else
        graphics.rectangle("fill", x - s * 0.8, y - s * 0.8, s * 1.6, s * 1.6)
    end
end

function Hud:drawCrosshair()
    local graphics = love.graphics
    local cx, cy, size = self.width / 2, self.height / 2, math.max(8, CROSSHAIR_SIZE * self.unit)
    graphics.setLineWidth(2)
    graphics.setColor(1, 1, 1, 0.9)
    graphics.line(cx - size, cy, cx + size, cy)
    graphics.line(cx, cy - size, cx, cy + size)
end

--- @param button HudButton
--- @param mode "fill"|"line"
local function drawButtonShape(button, mode)
    if button.kind == "move" then
        local side = button.size * 2
        love.graphics.rectangle(mode, button.x - button.size, button.y - button.size, side, side, button.size * 0.25)
    else
        love.graphics.circle(mode, button.x, button.y, button.size)
    end
end

--- Draws the touch controls' keys and buttons, brighter while held. Called by
--- TouchControls:draw.
--- @param touch TouchControls
function Hud:drawTouchControls(touch)
    local graphics = love.graphics
    graphics.push("all")
    local outlineWidth, iconLineWidth = math.max(2, 0.006 * self.unit), math.max(3, 0.012 * self.unit)
    for _, button in ipairs(self.buttons) do
        graphics.setLineWidth(outlineWidth)
        graphics.setColor(1, 1, 1, touch:isHeld(button.name) and 0.45 or 0.2)
        drawButtonShape(button, "fill")
        graphics.setColor(1, 1, 1, 0.6)
        drawButtonShape(button, "line")
        graphics.setColor(1, 1, 1, 0.9)
        graphics.setLineWidth(iconLineWidth)
        drawButtonIcon(button.name, button.x, button.y, button.size * 0.4)
    end
    graphics.pop()
end

--- Draws the crosshair. The input in use draws its own controls (if any).
function Hud:draw()
    love.graphics.push("all")
    self:drawCrosshair()
    love.graphics.pop()
end

return Hud
