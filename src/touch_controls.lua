--- Gesture tracking for the on-screen touch controls.
--
-- A touch that starts on a HUD button holds that button (tapping break/place
-- queues the action). Otherwise, one starting on the left half of the screen
-- becomes a floating joystick centered where it landed, and one on the right
-- half drags the view. Several touches work at once. The layout comes from the
-- HUD (src/hud.lua), which also draws the controls. Plain Lua, unit tested.

--- @class TouchState
--- @field kind "joystick"|"look"|"button"
--- @field button HudButtonName? For "button" touches.
--- @field originX number Where the touch started.
--- @field originY number
--- @field x number Where it is now.
--- @field y number

--- @class TouchJoystick
--- @field baseX number Where the joystick touch started (its center).
--- @field baseY number
--- @field knobX number Knob position, clamped to the joystick radius.
--- @field knobY number

--- @class TouchControls
--- @field hud Hud Layout: button positions, joystick size, screen size.
--- @field touches table<any, TouchState> LÖVE touch id -> state.
--- @field lookX number View drag since the last takeLook, in units.
--- @field lookY number
--- @field actions BlockAction[] Taps since the last takeActions.
local TouchControls = {}
TouchControls.__index = TouchControls

local DEADZONE = 0.15 -- joystick deflection ignored near the center

--- @param hud Hud
--- @return TouchControls
function TouchControls.new(hud)
    return setmetatable({ hud = hud, touches = {}, lookX = 0, lookY = 0, actions = {} }, TouchControls)
end

--- @param id any LÖVE touch id.
--- @param x number
--- @param y number
function TouchControls:pressed(id, x, y)
    local touch = { kind = "look", originX = x, originY = y, x = x, y = y }
    local target = self.hud:hitTest(x, y)
    if target and target ~= "toggle" then
        touch.kind, touch.button = "button", target
        if target == "break" or target == "place" then
            --- @cast target BlockAction
            self.actions[#self.actions + 1] = target
        end
    elseif x < self.hud.width / 2 then
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
        self.lookX = self.lookX + dx / self.hud.unit
        self.lookY = self.lookY + dy / self.hud.unit
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
    local radius = self.hud.joystickRadius
    local dx, dy = touch.x - touch.originX, touch.y - touch.originY
    local length = math.sqrt(dx * dx + dy * dy)
    if length > radius then
        dx, dy = dx * radius / length, dy * radius / length
    end
    return dx, dy
end

--- The held joystick, or nil if no touch is using it.
--- @return TouchJoystick?
function TouchControls:joystick()
    for _, touch in pairs(self.touches) do
        if touch.kind == "joystick" then
            local dx, dy = self:knobOffset(touch)
            return {
                baseX = touch.originX, baseY = touch.originY,
                knobX = touch.originX + dx, knobY = touch.originY + dy,
            }
        end
    end
    return nil
end

--- @param name HudButtonName
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
    local joystick = self:joystick()
    if joystick then
        local radius = self.hud.joystickRadius
        local dx, dy = joystick.knobX - joystick.baseX, joystick.knobY - joystick.baseY
        if math.sqrt(dx * dx + dy * dy) > DEADZONE * radius then
            forward, right = -dy / radius, dx / radius
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
--- @return BlockAction[]
function TouchControls:takeActions()
    local actions = self.actions
    self.actions = {}
    return actions
end

return TouchControls
