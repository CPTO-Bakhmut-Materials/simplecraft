--- On-screen controls for touch screens.
--
-- A touch that starts on the left half of the screen becomes a floating
-- joystick centered where it landed; one that starts on the right half drags
-- the view. Buttons in the bottom-right corner fly up/down while held and
-- break/place a block when tapped. Several touches work at once.
--
-- Everything except TouchControls:draw is plain Lua, so it can be unit tested.
-- Buttons show drawn icons rather than text: the love.js build can't create
-- font textures (WebGL 2 lacks the texture swizzle LÖVE uses for them).
-- Sizes scale with the shorter screen side ("unit"), so the layout works on
-- any resolution.

--- @alias TouchAction "break"|"place"
--- @alias TouchButtonName TouchAction|"up"|"down"

--- @class TouchButton
--- @field name TouchButtonName
--- @field x number Center, in pixels.
--- @field y number
--- @field radius number

--- @class TouchState
--- @field kind "joystick"|"look"|"button"
--- @field button TouchButtonName? For "button" touches.
--- @field originX number Where the touch started.
--- @field originY number
--- @field x number Where it is now.
--- @field y number

--- @class TouchControls
--- @field width number Screen size the layout was computed for.
--- @field height number
--- @field unit number Shorter screen side; all sizes are fractions of it.
--- @field joystickRadius number Joystick travel; full deflection at this distance.
--- @field joystickHomeX number Where the idle joystick is drawn.
--- @field joystickHomeY number
--- @field buttons TouchButton[]
--- @field touches table<any, TouchState> LÖVE touch id -> state.
--- @field lookX number View drag since the last takeLook, in units.
--- @field lookY number
--- @field actions TouchAction[] Taps since the last takeActions.
local TouchControls = {}
TouchControls.__index = TouchControls

local MARGIN = 0.05 -- of unit, from the screen edges
local JOYSTICK_RADIUS = 0.14
local BUTTON_RADIUS = 0.075
local BUTTON_SPACING = 2.4 -- distance between button centers, in button radii
local BUTTON_HIT_SCALE = 1.2 -- buttons accept touches slightly outside their circle
local DEADZONE = 0.15 -- joystick deflection ignored near the center

--- @return TouchControls
function TouchControls.new()
    return setmetatable({
        width = 0, height = 0, unit = 0,
        joystickRadius = 0, joystickHomeX = 0, joystickHomeY = 0,
        buttons = {},
        touches = {},
        lookX = 0, lookY = 0,
        actions = {},
    }, TouchControls)
end

--- Lays the controls out for a screen of the given size. Cheap to call every
--- frame: it does nothing unless the size changed.
--- @param width number
--- @param height number
function TouchControls:resize(width, height)
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

--- @param x number
--- @param y number
--- @return TouchButton?
function TouchControls:buttonAt(x, y)
    for _, button in ipairs(self.buttons) do
        local dx, dy, reach = x - button.x, y - button.y, button.radius * BUTTON_HIT_SCALE
        if dx * dx + dy * dy <= reach * reach then
            return button
        end
    end
    return nil
end

--- @param id any LÖVE touch id.
--- @param x number
--- @param y number
function TouchControls:pressed(id, x, y)
    local touch = { kind = "look", originX = x, originY = y, x = x, y = y }
    local button = self:buttonAt(x, y)
    if button then
        local name = button.name
        touch.kind, touch.button = "button", name
        if name == "break" or name == "place" then
            --- @cast name TouchAction
            self.actions[#self.actions + 1] = name
        end
    elseif x < self.width / 2 then
        touch.kind = "joystick"
    end
    self.touches[id] = touch
end

--- @param id any
--- @param x number
--- @param y number
--- @param dx number Movement since the last event, in pixels.
--- @param dy number
function TouchControls:moved(id, x, y, dx, dy)
    local touch = self.touches[id]
    if not touch then
        return
    end
    touch.x, touch.y = x, y
    if touch.kind == "look" then
        self.lookX = self.lookX + dx / self.unit
        self.lookY = self.lookY + dy / self.unit
    end
end

--- @param id any
function TouchControls:released(id)
    self.touches[id] = nil
end

--- Forgets all touches and pending input, e.g. when touch controls are turned off.
function TouchControls:reset()
    self.touches, self.actions = {}, {}
    self.lookX, self.lookY = 0, 0
end

--- Joystick knob offset from its origin, clamped to the joystick radius.
--- @param touch TouchState
--- @return number dx, number dy In pixels.
function TouchControls:knobOffset(touch)
    local dx, dy = touch.x - touch.originX, touch.y - touch.originY
    local length = math.sqrt(dx * dx + dy * dy)
    if length > self.joystickRadius then
        local scale = self.joystickRadius / length
        dx, dy = dx * scale, dy * scale
    end
    return dx, dy
end

--- @param name TouchButtonName
--- @return boolean
function TouchControls:isHeld(name)
    for _, touch in pairs(self.touches) do
        if touch.button == name then
            return true
        end
    end
    return false
end

--- Current movement input, matching Camera:move.
--- @return number forward -1..1
--- @return number right -1..1
--- @return number up -1, 0 or 1
function TouchControls:movement()
    local forward, right = 0, 0
    for _, touch in pairs(self.touches) do
        if touch.kind == "joystick" then
            local dx, dy = self:knobOffset(touch)
            if math.sqrt(dx * dx + dy * dy) > DEADZONE * self.joystickRadius then
                forward, right = -dy / self.joystickRadius, dx / self.joystickRadius
            end
        end
    end
    local up = (self:isHeld("up") and 1 or 0) - (self:isHeld("down") and 1 or 0)
    return forward, right, up
end

--- Returns the view drag since the last call, in units (fractions of the
--- shorter screen side), and resets it.
--- @return number dx, number dy
function TouchControls:takeLook()
    local dx, dy = self.lookX, self.lookY
    self.lookX, self.lookY = 0, 0
    return dx, dy
end

--- Returns the buttons tapped since the last call, oldest first, and clears them.
--- @return TouchAction[]
function TouchControls:takeActions()
    local actions = self.actions
    self.actions = {}
    return actions
end

--- Icon for a button, centered on (x, y) with half-size `s`: triangles for
--- up/down, a cross for break, a block (square) for place.
--- @param name TouchButtonName
--- @param x number
--- @param y number
--- @param s number
local function drawIcon(name, x, y, s)
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

--- Draws the controls over the game. Needs LÖVE.
function TouchControls:draw()
    local graphics = love.graphics
    graphics.push("all")
    graphics.setLineWidth(math.max(2, 0.006 * self.unit))

    -- Joystick: drawn where it is held, or at its home position when idle.
    local baseX, baseY, knobX, knobY = self.joystickHomeX, self.joystickHomeY, self.joystickHomeX, self.joystickHomeY
    for _, touch in pairs(self.touches) do
        if touch.kind == "joystick" then
            local dx, dy = self:knobOffset(touch)
            baseX, baseY, knobX, knobY = touch.originX, touch.originY, touch.originX + dx, touch.originY + dy
        end
    end
    graphics.setColor(1, 1, 1, 0.15)
    graphics.circle("fill", baseX, baseY, self.joystickRadius)
    graphics.setColor(1, 1, 1, 0.5)
    graphics.circle("line", baseX, baseY, self.joystickRadius)
    graphics.setColor(1, 1, 1, 0.6)
    graphics.circle("fill", knobX, knobY, self.joystickRadius * 0.4)

    for _, button in ipairs(self.buttons) do
        graphics.setColor(1, 1, 1, self:isHeld(button.name) and 0.45 or 0.2)
        graphics.circle("fill", button.x, button.y, button.radius)
        graphics.setColor(1, 1, 1, 0.6)
        graphics.circle("line", button.x, button.y, button.radius)
        graphics.setColor(1, 1, 1, 0.9)
        graphics.setLineWidth(math.max(3, 0.012 * self.unit))
        drawIcon(button.name, button.x, button.y, button.radius * 0.4)
        graphics.setLineWidth(math.max(2, 0.006 * self.unit))
    end
    graphics.pop()
end

return TouchControls
