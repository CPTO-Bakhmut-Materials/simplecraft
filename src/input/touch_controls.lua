--- Touch input: the on-screen controls.
--
-- A touch that starts on a HUD button holds that button (tapping break/place
-- queues the action). One that starts on a direction key holds whichever key
-- is under the finger as it slides, like a gamepad's D-pad. Any other touch
-- drags the view. Several touches work at once. The layout comes from the HUD
-- (src/hud.lua), which also draws the controls. Plain Lua, unit tested.
--
-- Used instead of mouse & keyboard for the whole session; see src/input/init.lua.

local Config = require("src.config")

--- @class TouchState
--- @field kind "button"|"move"|"look" "move" touches started on a move key.
--- @field button HudButtonName? The held button; for "move", nil while between keys.

--- @class TouchControls
--- @field hud Hud Layout: button positions and sizes.
--- @field touches table<any, TouchState> LÖVE touch id -> state.
--- @field lookX number View drag since the last frame, in units (fractions of the shorter screen side).
--- @field lookY number
--- @field actions BlockAction[] Taps since the last frame.
local TouchControls = {}
TouchControls.__index = TouchControls

--- @param hud Hud
--- @return TouchControls
function TouchControls.new(hud)
    return setmetatable({ hud = hud, touches = {}, lookX = 0, lookY = 0, actions = {} }, TouchControls)
end

--- @param id any LÖVE touch id.
--- @param x number
--- @param y number
function TouchControls:pressed(id, x, y)
    local button = self.hud:hitTest(x, y)
    if not button then
        self.touches[id] = { kind = "look" }
    elseif button.kind == "move" then
        self.touches[id] = { kind = "move", button = button.name }
    else
        self.touches[id] = { kind = "button", button = button.name }
        if button.action then
            self.actions[#self.actions + 1] = button.action
        end
    end
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
    if touch.kind == "look" then
        self.lookX = self.lookX + dx / self.hud.unit
        self.lookY = self.lookY + dy / self.hud.unit
    elseif touch.kind == "move" then
        local button = self.hud:hitTest(x, y)
        touch.button = button and button.kind == "move" and button.name or nil
    end
end

--- @param id any
function TouchControls:released(id)
    self.touches[id] = nil
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

--- @param controls TouchControls
--- @param positive HudButtonName
--- @param negative HudButtonName
--- @return number -1, 0 or 1
local function axis(controls, positive, negative)
    return (controls:isHeld(positive) and 1 or 0) - (controls:isHeld(negative) and 1 or 0)
end

--- Returns this frame's input and clears what was collected for it.
--- @return InputFrame
function TouchControls:takeFrame()
    local lookSpeed = Config.touchLookSpeed
    local frame = {
        forward = axis(self, "forward", "back"), right = axis(self, "right", "left"), up = axis(self, "up", "down"),
        fast = false,
        yaw = -self.lookX * lookSpeed, pitch = -self.lookY * lookSpeed,
        actions = self.actions,
    }
    self.lookX, self.lookY, self.actions = 0, 0, {}
    return frame
end

--- Draws the controls (the HUD does the drawing, since it owns the layout).
function TouchControls:draw()
    self.hud:drawTouchControls(self)
end

return TouchControls
