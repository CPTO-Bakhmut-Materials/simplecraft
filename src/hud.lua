--- Everything drawn over the world: the crosshair and, in touch mode, the
--- direction keys (bottom-left) and buttons (bottom-right).
--
-- The HUD owns the on-screen layout: Hud:resize places every element for the
-- current screen and Hud:hitTest tells what is under a point. Sizes are
-- fractions of the shorter screen side ("unit"), so the layout fits any
-- resolution. Everything except Hud:draw is plain Lua, so it can be unit tested.
--
-- Labels are drawn shapes, not text, so the HUD does not depend on fonts.

--- @alias MoveDirection "forward"|"back"|"left"|"right"
--- @alias HudButtonName BlockAction|MoveDirection|"up"|"down"

--- @class HudButton
--- @field name HudButtonName
--- @field shape "circle"|"square" Direction keys are squares, the other buttons circles.
--- @field x number Center, in pixels.
--- @field y number
--- @field size number Radius of a circle, half the side of a square.

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
    local function directionKey(name, column, row)
        return { name = name, shape = "square", x = padX + column * keyStep, y = padY + row * keyStep, size = key / 2 }
    end
    self.keyGap = gap

    -- 2x2 grid in the bottom-right corner: fly buttons above the action buttons.
    local radius = BUTTON_RADIUS * unit
    local right, bottom = width - margin - radius, height - margin - radius
    local step = BUTTON_SPACING * radius
    local function roundButton(name, x, y)
        return { name = name, shape = "circle", x = x, y = y, size = radius }
    end

    self.buttons = {
        directionKey("forward", 0, -1), directionKey("back", 0, 1),
        directionKey("left", -1, 0), directionKey("right", 1, 0),
        roundButton("place", right, bottom), roundButton("break", right - step, bottom),
        roundButton("up", right, bottom - step), roundButton("down", right - step, bottom - step),
    }
end

--- The touch button under a screen point, or nil.
--- @param x number
--- @param y number
--- @return HudButtonName?
function Hud:hitTest(x, y)
    for _, button in ipairs(self.buttons) do
        local dx, dy = x - button.x, y - button.y
        if button.shape == "square" then
            -- Up to half the gap: neighboring keys meet but never overlap.
            local reach = button.size + self.keyGap / 2
            if math.abs(dx) <= reach and math.abs(dy) <= reach then
                return button.name
            end
        else
            local reach = button.size * BUTTON_HIT_SCALE
            if dx * dx + dy * dy <= reach * reach then
                return button.name
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
    if button.shape == "square" then
        local side = button.size * 2
        love.graphics.rectangle(mode, button.x - button.size, button.y - button.size, side, side, button.size * 0.25)
    else
        love.graphics.circle(mode, button.x, button.y, button.size)
    end
end

--- Direction keys and buttons, brighter while held.
--- @param touch TouchControls
function Hud:drawTouchControls(touch)
    local graphics = love.graphics
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
end

--- Draws the whole HUD over the world.
--- @param touchMode boolean
--- @param touch TouchControls Its state is shown in touch mode.
function Hud:draw(touchMode, touch)
    love.graphics.push("all")
    self:drawCrosshair()
    if touchMode then
        self:drawTouchControls(touch)
    end
    love.graphics.pop()
end

return Hud
