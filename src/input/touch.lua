--- Touch input: the on-screen controls.
--
-- A touch that starts on a button holds that button (tapping break/place
-- queues the action). One that starts on a move key holds whichever key is
-- under the finger as it slides, like a gamepad's D-pad. Any other touch drags
-- the view. Several touches work at once. Button positions come from
-- src/input/touch_layout.lua. Everything except TouchInput:draw is plain Lua,
-- so it can be unit tested.
--
-- Used instead of mouse & keyboard for the whole session; see src/input/init.lua.

local Config = require("src.config")
local TouchLayout = require("src.input.touch_layout")

--- @class TouchState
--- @field kind "button"|"move"|"look" "move" touches started on a move key.
--- @field button TouchButtonName? The held button; for "move", nil while between keys.

--- @class TouchInput
--- @field layout TouchLayout Button positions, kept up to date with the screen size.
--- @field screenSize fun(): number, number Returns the screen's width and height.
--- @field touches table<any, TouchState> LÖVE touch id -> state.
--- @field lookX number View drag since the last frame, in units (fractions of the shorter screen side).
--- @field lookY number
--- @field actions BlockAction[] Taps since the last frame.
local TouchInput = {}
TouchInput.__index = TouchInput

--- @param screenSize fun(): number, number Returns the screen's width and height, e.g. love.graphics.getDimensions.
--- @return TouchInput
function TouchInput.new(screenSize)
    return setmetatable({
        layout = TouchLayout.new(), screenSize = screenSize,
        touches = {}, lookX = 0, lookY = 0, actions = {},
    }, TouchInput)
end

--- The layout for the current screen size. Checked on every use: the screen can
--- change size at any time (a window manager resizing the window as it opens
--- does not always trigger love.resize).
--- @return TouchLayout
function TouchInput:currentLayout()
    self.layout:resize(self.screenSize())
    return self.layout
end

--- @param id any LÖVE touch id.
--- @param x number
--- @param y number
function TouchInput:pressed(id, x, y)
    local button = self:currentLayout():hitTest(x, y)
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
function TouchInput:moved(id, x, y, dx, dy)
    local touch = self.touches[id]
    if not touch then
        return
    end
    local layout = self:currentLayout()
    if touch.kind == "look" then
        self.lookX = self.lookX + dx / layout.unit
        self.lookY = self.lookY + dy / layout.unit
    elseif touch.kind == "move" then
        local button = layout:hitTest(x, y)
        touch.button = button and button.kind == "move" and button.name or nil
    end
end

--- @param id any
function TouchInput:released(id)
    self.touches[id] = nil
end

--- @param name TouchButtonName
--- @return boolean
function TouchInput:isHeld(name)
    for _, touch in pairs(self.touches) do
        if touch.button == name then
            return true
        end
    end
    return false
end

--- @param input TouchInput
--- @param positive TouchButtonName
--- @param negative TouchButtonName
--- @return number -1, 0 or 1
local function axis(input, positive, negative)
    return (input:isHeld(positive) and 1 or 0) - (input:isHeld(negative) and 1 or 0)
end

--- Returns this frame's input and clears what was collected for it.
--- @return InputFrame
function TouchInput:takeFrame()
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

-- Drawing (needs LÖVE). Labels are drawn shapes, not text, so the controls do
-- not depend on fonts. ---------------------------------------------------------

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

-- Screen direction of each move key's arrow.
local ARROWS = { forward = { 0, -1 }, back = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }

--- Button icon centered on (x, y) with half-size `s`: an arrow for each move
--- key, double arrows for flying up/down, a cross for break, a block (square)
--- for place.
--- @param name TouchButtonName
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

--- @param button TouchButton
--- @param mode "fill"|"line"
local function drawButtonShape(button, mode)
    if button.kind == "move" then
        local side = button.size * 2
        love.graphics.rectangle(mode, button.x - button.size, button.y - button.size, side, side, button.size * 0.25)
    else
        love.graphics.circle(mode, button.x, button.y, button.size)
    end
end

--- Draws the keys and buttons, brighter while held.
function TouchInput:draw()
    local graphics = love.graphics
    local layout = self:currentLayout()
    local outlineWidth, iconLineWidth = math.max(2, 0.006 * layout.unit), math.max(3, 0.012 * layout.unit)
    graphics.push("all")
    for _, button in ipairs(layout.buttons) do
        graphics.setLineWidth(outlineWidth)
        graphics.setColor(1, 1, 1, self:isHeld(button.name) and 0.45 or 0.2)
        drawButtonShape(button, "fill")
        graphics.setColor(1, 1, 1, 0.6)
        drawButtonShape(button, "line")
        graphics.setColor(1, 1, 1, 0.9)
        graphics.setLineWidth(iconLineWidth)
        drawButtonIcon(button.name, button.x, button.y, button.size * 0.4)
    end
    graphics.pop()
end

return TouchInput
