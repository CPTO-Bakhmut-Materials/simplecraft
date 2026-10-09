local t = require("tests.lib")
local Mat4 = require("src.math.mat4")
local Vec3 = require("src.math.vec3")

local IDENTITY = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }

local function ndc(m, x, y, z)
    local cx, cy, cz, cw = Mat4.transformPoint(m, Vec3.new(x, y, z))
    return cx / cw, cy / cw, cz / cw
end

t.test("mat4: multiply by identity is a no-op", function()
    local m = Mat4.perspective(1, 1.5, 0.1, 100)
    local product = Mat4.multiply(IDENTITY, m)
    for i = 1, 16 do
        t.near(product[i], m[i], "element " .. i)
    end
end)

t.test("mat4: perspective maps near/far planes to depth -1/1", function()
    local m = Mat4.perspective(math.rad(90), 1, 0.5, 50)
    local _, _, nearDepth = ndc(m, 0, 0, -0.5)
    local _, _, farDepth = ndc(m, 0, 0, -50)
    t.near(nearDepth, -1); t.near(farDepth, 1)
end)

t.test("mat4: 90 degree fov puts the frustum edge at x = 1", function()
    local x = ndc(Mat4.perspective(math.rad(90), 1, 0.1, 10), 2, 0, -2)
    t.near(x, 1)
end)

t.test("mat4: lookAlong maps eye to origin and forward to -Z", function()
    local view = Mat4.lookAlong(Vec3.new(3, 4, 5), Vec3.new(1, 0, 0), Vec3.new(0, 0, 1))
    local x, y, z = Mat4.transformPoint(view, Vec3.new(3, 4, 5))
    t.near(x, 0); t.near(y, 0); t.near(z, 0)
    x, y, z = Mat4.transformPoint(view, Vec3.new(5, 4, 5))
    t.near(x, 0); t.near(y, 0); t.near(z, -2)
    -- World up stays screen up; +Y world is to the left when looking along +X.
    local _, upY = Mat4.transformPoint(view, Vec3.new(3, 4, 6))
    t.near(upY, 1)
    local leftX = Mat4.transformPoint(view, Vec3.new(3, 5, 5))
    t.near(leftX, -1)
end)
