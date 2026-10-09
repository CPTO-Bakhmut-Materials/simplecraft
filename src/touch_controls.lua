--- Gesture tracking for the on-screen touch controls.
--
-- A touch that starts on a HUD button holds that button (tapping break/place
-- queues the action). One that starts on a direction key holds whichever key
-- is under the finger as it slides, like a gamepad's D-pad. Any other touch
-- drags the view. Several touches work at once. The layout comes from the HUD
-- (src/hud.lua), which also draws the controls. Plain Lua, unit tested.

--- @class TouchState
--- @field kind "button"|"direction"|"look"
--- @field button HudButtonName? The held button; for "direction", nil while between keys.

--- @class TouchControls
--- @field hud Hud Layout: button positions and sizes.
--- @field touches table<any, TouchState> LÖVE touch id -> state.
--- @field lookX number View drag since the last takeLook, in units.
--- @field lookY number
--- @field actions BlockAction[] Taps since the last takeActions.
local TouchControls = {}
TouchControls.__index = TouchControls

--- @type table<HudButtonName, true>
local DIRECTIONS = { forward = true, back = true, left = true, right = true }

--- @param hud Hud
--- @return TouchControls
function TouchControls.new(hud)
    return setmetatable({ hud = hud, touches = {}, lookX = 0, lookY = 0, actions = {} }, TouchControls)
end

--- @param id any LÖVE touch id.
--- @param x number
--- @param y number
function TouchControls:pressed(id, x, y)
    local target = self.hud:hitTest(x, y)
    if not target then
        self.touches[id] = { kind = "look" }
    elseif DIRECTIONS[target] then
        self.touches[id] = { kind = "direction", button = target }
    else
        self.touches[id] = { kind = "button", button = target }
        if target == "break" or target == "place" then
            --- @cast target BlockAction
            self.actions[#self.actions + 1] = target
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
    elseif touch.kind == "direction" then
        local target = self.hud:hitTest(x, y)
        touch.button = DIRECTIONS[target] and target or nil
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

--- @param positive HudButtonName
--- @param negative HudButtonName
--- @return number -1, 0 or 1
function TouchControls:axis(positive, negative)
    return (self:isHeld(positive) and 1 or 0) - (self:isHeld(negative) and 1 or 0)
end

--- Current movement input, matching Camera:move.
--- @return number forward -1, 0 or 1
--- @return number right -1, 0 or 1
--- @return number up -1, 0 or 1
function TouchControls:movement()
    return self:axis("forward", "back"), self:axis("right", "left"), self:axis("up", "down")
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
