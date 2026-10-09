local t = require("tests.lib")
local Camera = require("src.render.camera")
local Vec3 = require("src.math.vec3")

local function newCamera(yaw, pitch)
    return Camera.new({ yaw = yaw, pitch = pitch, fov = 1, near = 0.1, far = 100 })
end

t.test("camera: forward follows yaw and pitch", function()
    local forward = newCamera(0, 0):forward()
    t.near(forward.x, 1); t.near(forward.y, 0); t.near(forward.z, 0)
    forward = newCamera(math.pi / 2, 0):forward()
    t.near(forward.x, 0); t.near(forward.y, 1); t.near(forward.z, 0)
end)

t.test("camera: pitch is clamped short of vertical", function()
    local camera = newCamera(0, 0)
    camera:rotate(0, 10)
    t.ok(camera.pitch < math.pi / 2, "pitch should stay below 90 degrees")
    camera:rotate(0, -20)
    t.ok(camera.pitch > -math.pi / 2, "pitch should stay above -90 degrees")
end)

t.test("camera: moves at constant speed in any direction", function()
    local camera = newCamera(0, 0)
    camera:move(1, 1, 1, 1, 3)
    t.near(camera.position:length(), 3)
end)

t.test("camera: strafing right is clockwise from forward", function()
    local camera = newCamera(0, 0) -- facing +X, so right is -Y
    camera:move(1, 0, 1, 0, 1)
    t.near(camera.position.x, 0); t.near(camera.position.y, -1)
end)

t.test("camera: no input means no movement", function()
    local camera = newCamera(0.3, 0.2)
    camera:move(1, 0, 0, 0, 10)
    t.eq(camera.position, Vec3.new(0, 0, 0))
end)
