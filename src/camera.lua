--- Free-flying first-person camera (Z up). No LÖVE dependency.

local Mat4 = require("src.math.mat4")
local Vec3 = require("src.math.vec3")

--- @class CameraOptions
--- @field position Vec3? Defaults to the origin.
--- @field yaw number? Counter-clockwise from +X.
--- @field pitch number? Positive looks up.
--- @field fov number Vertical field of view.
--- @field near number
--- @field far number

--- @class Camera
--- @field position Vec3 Replaced (never mutated) when the camera moves.
--- @field yaw number
--- @field pitch number
--- @field fov number
--- @field near number
--- @field far number
local Camera = {}
Camera.__index = Camera

local MAX_PITCH = math.rad(89) -- keeps the view direction off the up axis
local UP = Vec3.new(0, 0, 1)

--- @param options CameraOptions Angles in radians.
--- @return Camera
function Camera.new(options)
    local camera = setmetatable({
        position = options.position or Vec3.new(0, 0, 0),
        yaw = options.yaw or 0, pitch = 0,
        fov = options.fov, near = options.near, far = options.far,
    }, Camera)
    camera:rotate(0, options.pitch or 0)
    return camera
end

--- Unit view direction.
--- @return Vec3
function Camera:forward()
    local cosPitch = math.cos(self.pitch)
    return Vec3.new(cosPitch * math.cos(self.yaw), cosPitch * math.sin(self.yaw), math.sin(self.pitch))
end

--- Turns the camera; pitch is clamped short of straight up or down.
--- @param deltaYaw number
--- @param deltaPitch number
function Camera:rotate(deltaYaw, deltaPitch)
    self.yaw = (self.yaw + deltaYaw) % (2 * math.pi)
    self.pitch = math.max(-MAX_PITCH, math.min(MAX_PITCH, self.pitch + deltaPitch))
end

--- Moves the camera. Inputs are -1..1: `forward` follows the view direction,
--- `right` strafes horizontally, `up` moves along world Z.
--- @param dt number Seconds.
--- @param forward number
--- @param right number
--- @param up number
--- @param speed number Blocks per second.
function Camera:move(dt, forward, right, up, speed)
    local rightDirection = Vec3.new(math.sin(self.yaw), -math.cos(self.yaw), 0)
    local velocity = self:forward() * forward + rightDirection * right + UP * up
    local length = velocity:length()
    if length > 0 then
        self.position = self.position + velocity * (speed * dt / length)
    end
end

--- @param aspect number Viewport width / height.
--- @return Mat4
function Camera:viewProjection(aspect)
    local view = Mat4.lookAlong(self.position, self:forward(), UP)
    return Mat4.multiply(Mat4.perspective(self.fov, aspect, self.near, self.far), view)
end

return Camera
