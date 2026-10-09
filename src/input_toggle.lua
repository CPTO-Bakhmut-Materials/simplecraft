--- Button in the top-right corner that switches between mouse/keyboard and
--- touch controls. Drawn as a two-part pill: a mouse icon on the left, a phone
--- icon on the right, with the active mode highlighted. Icons are drawn shapes,
--- not text, so it does not depend on fonts.
--
-- Everything except InputToggle:draw is plain Lua, so it can be unit tested.

--- @class InputToggle
--- @field x number Top-left corner, in pixels.
--- @field y number
--- @field width number
--- @field height number
--- @field screenWidth number Screen size the layout was computed for.
--- @field screenHeight number
local InputToggle = {}
InputToggle.__index = InputToggle

-- Fractions of the shorter screen side.
local MARGIN = 0.04
local HEIGHT = 0.09
local WIDTH = 0.2
local HIT_PADDING = 0.02 -- accepted outside the pill, for imprecise fingers

--- @return InputToggle
function InputToggle.new()
    return setmetatable({ x = 0, y = 0, width = 0, height = 0, screenWidth = 0, screenHeight = 0 }, InputToggle)
end

--- Lays the button out for a screen of the given size; does nothing unless the
--- size changed.
--- @param width number
--- @param height number
function InputToggle:resize(width, height)
    if width == self.screenWidth and height == self.screenHeight then
        return
    end
    local unit = math.min(width, height)
    self.screenWidth, self.screenHeight = width, height
    self.width, self.height = WIDTH * unit, HEIGHT * unit
    self.x, self.y = width - MARGIN * unit - self.width, MARGIN * unit
end

--- @param x number
--- @param y number
--- @return boolean
function InputToggle:contains(x, y)
    local padding = HIT_PADDING * math.min(self.screenWidth, self.screenHeight)
    return x >= self.x - padding and x <= self.x + self.width + padding
        and y >= self.y - padding and y <= self.y + self.height + padding
end

--- Mouse: a rounded body with a line between the buttons. Centered on (x, y), half-height `s`.
--- @param x number
--- @param y number
--- @param s number
local function drawMouseIcon(x, y, s)
    local graphics = love.graphics
    graphics.rectangle("line", x - s * 0.6, y - s, s * 1.2, s * 2, s * 0.6)
    graphics.line(x, y - s, x, y - s * 0.3)
end

--- Phone: a tall rounded body with a home button.
--- @param x number
--- @param y number
--- @param s number
local function drawPhoneIcon(x, y, s)
    local graphics = love.graphics
    graphics.rectangle("line", x - s * 0.55, y - s, s * 1.1, s * 2, s * 0.2)
    graphics.circle("fill", x, y + s * 0.65, s * 0.15)
end

--- Draws the button. Needs LÖVE.
--- @param touchMode boolean Which half to highlight.
function InputToggle:draw(touchMode)
    local graphics = love.graphics
    local half, radius = self.width / 2, self.height / 2
    local iconSize = self.height * 0.3
    graphics.push("all")
    graphics.setLineWidth(math.max(2, self.height * 0.06))

    graphics.setColor(0, 0, 0, 0.25)
    graphics.rectangle("fill", self.x, self.y, self.width, self.height, radius)
    graphics.setColor(1, 1, 1, 0.35)
    local activeX = touchMode and self.x + half or self.x
    graphics.rectangle("fill", activeX, self.y, half, self.height, radius)
    graphics.setColor(1, 1, 1, 0.6)
    graphics.rectangle("line", self.x, self.y, self.width, self.height, radius)

    local centerY = self.y + radius
    graphics.setColor(1, 1, 1, touchMode and 0.6 or 1)
    drawMouseIcon(self.x + half / 2, centerY, iconSize)
    graphics.setColor(1, 1, 1, touchMode and 1 or 0.6)
    drawPhoneIcon(self.x + half * 1.5, centerY, iconSize)
    graphics.pop()
end

return InputToggle
