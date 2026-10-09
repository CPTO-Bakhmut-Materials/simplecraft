--- Everything drawn over the world: the crosshair and, in touch mode, the
--- joystick and buttons.
--
-- The HUD owns the on-screen layout: Hud:resize places every element for the
-- current screen and Hud:hitTest tells what is under a point. Sizes are
-- fractions of the shorter screen side ("unit"), so the layout fits any
-- resolution. Everything except Hud:draw is plain Lua, so it can be unit tested.
--
-- Labels are drawn shapes, not text, so the HUD does not depend on fonts.

--- @alias HudButtonName BlockAction|"up"|"down"

--- @class HudButton
--- @field name HudButtonName
--- @field x number Center, in pixels.
--- @field y number
--- @field radius number

--- @class Hud
--- @field width number Screen size the layout was computed for.
--- @field height number
--- @field unit number Shorter screen side; all sizes are fractions of it.
--- @field joystickRadius number Joystick travel; full deflection at this distance.
--- @field joystickHomeX number Where the idle joystick is drawn.
--- @field joystickHomeY number
--- @field buttons HudButton[] Touch buttons, bottom-right.
local Hud = {}
Hud.__index = Hud

-- Fractions of `unit`.
local MARGIN = 0.05 -- from the screen edges
local JOYSTICK_RADIUS = 0.14
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

    self.joystickRadius = JOYSTICK_RADIUS * unit
    self.joystickHomeX = margin + self.joystickRadius
    self.joystickHomeY = height - margin - self.joystickRadius

    -- 2x2 grid in the bottom-right corner: fly buttons above the action buttons.
    local radius = BUTTON_RADIUS * unit
    local right, bottom = width - margin - radius, height - margin - radius
    local step = BUTTON_SPACING * radius
    self.buttons = {
        { name = "place", x = right, y = bottom, radius = radius },
        { name = "break", x = right - step, y = bottom, radius = radius },
        { name = "up", x = right, y = bottom - step, radius = radius },
        { name = "down", x = right - step, y = bottom - step, radius = radius },
    }
end

--- The touch button under a screen point, or nil.
--- @param x number
--- @param y number
--- @return HudButtonName?
function Hud:hitTest(x, y)
    for _, button in ipairs(self.buttons) do
        local dx, dy, reach = x - button.x, y - button.y, button.radius * BUTTON_HIT_SCALE
        if dx * dx + dy * dy <= reach * reach then
            return button.name
        end
    end
    return nil
end

-- Drawing (needs LÖVE) --------------------------------------------------------

--- Button icon centered on (x, y) with half-size `s`: triangles for up/down, a
--- cross for break, a block (square) for place.
--- @param name HudButtonName
--- @param x number
--- @param y number
--- @param s number
local function drawButtonIcon(name, x, y, s)
    local graphics = love.graphics
    if name == "up" then
        graphics.polygon("fill", x, y - s, x + s, y + s * 0.7, x - s, y + s * 0.7)
    elseif name == "down" then
        graphics.polygon("fill", x, y + s, x + s, y - s * 0.7, x - s, y - s * 0.7)
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

--- Joystick (where it is held, or at its home position when idle) and buttons.
--- @param touch TouchControls
function Hud:drawTouchControls(touch)
    local graphics = love.graphics
    graphics.setLineWidth(math.max(2, 0.006 * self.unit))

    local baseX, baseY = self.joystickHomeX, self.joystickHomeY
    local knobX, knobY = baseX, baseY
    local joystick = touch:joystick()
    if joystick then
        baseX, baseY, knobX, knobY = joystick.baseX, joystick.baseY, joystick.knobX, joystick.knobY
    end
    graphics.setColor(1, 1, 1, 0.15)
    graphics.circle("fill", baseX, baseY, self.joystickRadius)
    graphics.setColor(1, 1, 1, 0.5)
    graphics.circle("line", baseX, baseY, self.joystickRadius)
    graphics.setColor(1, 1, 1, 0.6)
    graphics.circle("fill", knobX, knobY, self.joystickRadius * 0.4)

    local iconLineWidth = math.max(3, 0.012 * self.unit)
    for _, button in ipairs(self.buttons) do
        graphics.setLineWidth(math.max(2, 0.006 * self.unit))
        graphics.setColor(1, 1, 1, touch:isHeld(button.name) and 0.45 or 0.2)
        graphics.circle("fill", button.x, button.y, button.radius)
        graphics.setColor(1, 1, 1, 0.6)
        graphics.circle("line", button.x, button.y, button.radius)
        graphics.setColor(1, 1, 1, 0.9)
        graphics.setLineWidth(iconLineWidth)
        drawButtonIcon(button.name, button.x, button.y, button.radius * 0.4)
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
