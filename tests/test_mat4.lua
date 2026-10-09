local t = require("tests.lib")
local Mat4 = require("src.math.mat4")
local Vec3 = require("src.math.vec3")

--- @param actual Vec3
--- @param expected Vec3
--- @param message string?
local function nearVec(actual, expected, message)
    for _, axis in ipairs(Vec3.AXES) do
        t.near(actual[axis], expected[axis], (message and message .. " " or "") .. axis)
    end
end

t.test("mat4: multiplication applies the right-hand matrix first", function()
    local view = Mat4.lookAlong(Vec3.new(3, 4, 5), Vec3.new(1, 0, 0), Vec3.new(0, 0, 1))
    local projection = Mat4.perspective(math.rad(90), 1, 0.5, 50)
    local point = Vec3.new(8, 4.5, 5)
    nearVec((projection * view):transformPoint(point), projection:transformPoint(view:transformPoint(point)))
end)

t.test("mat4: perspective maps near/far planes to depth -1/1", function()
    local m = Mat4.perspective(math.rad(90), 1, 0.5, 50)
    t.near(m:transformPoint(Vec3.new(0, 0, -0.5)).z, -1)
    t.near(m:transformPoint(Vec3.new(0, 0, -50)).z, 1)
end)

t.test("mat4: 90 degree fov puts the frustum edge at x = 1", function()
    t.near(Mat4.perspective(math.rad(90), 1, 0.1, 10):transformPoint(Vec3.new(2, 0, -2)).x, 1)
end)

t.test("mat4: lookAlong maps eye to origin and forward to -Z", function()
    local view = Mat4.lookAlong(Vec3.new(3, 4, 5), Vec3.new(1, 0, 0), Vec3.new(0, 0, 1))
    nearVec(view:transformPoint(Vec3.new(3, 4, 5)), Vec3.ZERO, "eye")
    nearVec(view:transformPoint(Vec3.new(5, 4, 5)), Vec3.new(0, 0, -2), "ahead")
    -- World up stays screen up; +Y world is to the left when looking along +X.
    nearVec(view:transformPoint(Vec3.new(3, 4, 6)), Vec3.new(0, 1, 0), "above")
    nearVec(view:transformPoint(Vec3.new(3, 5, 5)), Vec3.new(-1, 0, 0), "left")
end)

t.test("mat4: needs exactly 16 values", function()
    t.raises(function() Mat4.new({ 1, 2, 3 }) end, "16 values")
end)
