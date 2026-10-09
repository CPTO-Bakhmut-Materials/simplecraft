--- Where the on-screen touch buttons are: move keys in a plus shape in the
--- bottom-left corner, fly and action buttons in a 2x2 grid in the bottom-right.
--
-- TouchLayout:resize places the buttons for a screen size and
-- TouchLayout:hitTest tells which one is under a point. Sizes are fractions of
-- the shorter screen side ("unit"), so the layout fits any resolution. Plain
-- Lua, unit tested; src/input/touch.lua draws the buttons.

--- @alias TouchButtonName "forward"|"back"|"left"|"right"|"up"|"down"|BlockAction

--- @class TouchButton
--- @field name TouchButtonName
--- @field kind "move"|"fly"|"action" Move keys are squares (bottom-left), the rest circles (bottom-right).
--- @field action BlockAction? What an "action" button does.
--- @field x number Center, in pixels.
--- @field y number
--- @field size number Half the side of a square, radius of a circle.

--- @class TouchLayout
--- @field width number Screen size the layout was computed for.
--- @field height number
--- @field unit number Shorter screen side; all sizes are fractions of it.
--- @field keyGap number Space between move keys, in pixels.
--- @field buttons TouchButton[]
local TouchLayout = {}
TouchLayout.__index = TouchLayout

-- Fractions of `unit`.
local MARGIN = 0.05 -- from the screen edges
local KEY_SIZE = 0.12 -- side of a move key
local KEY_GAP = 0.015
local BUTTON_RADIUS = 0.075

local BUTTON_SPACING = 2.4 -- distance between button centers, in button radii
local BUTTON_HIT_SCALE = 1.2 -- buttons accept touches slightly outside their circle

--- @return TouchLayout
function TouchLayout.new()
    local self = setmetatable({}, TouchLayout)
    self:resize(0, 0)
    return self
end

--- Places every button for a screen of the given size. Cheap to call often:
--- it does nothing unless the size changed.
--- @param width number
--- @param height number
function TouchLayout:resize(width, height)
    if width == self.width and height == self.height then
        return
    end
    local unit = math.min(width, height)
    local margin = MARGIN * unit
    self.width, self.height, self.unit = width, height, unit

    -- Move keys in a plus shape in the bottom-left corner, around an empty center.
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
    --- @return TouchButton
    local function actionButton(action, x, y)
        return { name = action, kind = "action", action = action, x = x, y = y, size = radius }
    end

    self.buttons = {
        moveKey("forward", 0, -1), moveKey("back", 0, 1), moveKey("left", -1, 0), moveKey("right", 1, 0),
        flyButton("up", right, bottom - step), flyButton("down", right - step, bottom - step),
        actionButton("place", right, bottom), actionButton("break", right - step, bottom),
    }
end

--- The button under a screen point, or nil.
--- @param x number
--- @param y number
--- @return TouchButton?
function TouchLayout:hitTest(x, y)
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

return TouchLayout
