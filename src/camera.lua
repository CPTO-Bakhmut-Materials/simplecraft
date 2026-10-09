--- Free-flying first-person camera (Z up). No LÖVE dependency.

local Mat4 = require("src.mat4")

--- @class CameraOptions
--- @field x number?
--- @field y number?
--- @field z number?
--- @field yaw number? Counter-clockwise from +X.
--- @field pitch number? Positive looks up.
--- @field fov number Vertical field of view.
--- @field near number
--- @field far number

--- @class Camera
--- @field x number
--- @field y number
--- @field z number
--- @field yaw number
--- @field pitch number
--- @field fov number
--- @field near number
--- @field far number
local Camera = {}
Camera.__index = Camera

local MAX_PITCH = math.rad(89) -- keeps the view direction off the up axis

--- @param options CameraOptions Angles in radians.
--- @return Camera
function Camera.new(options)
    local camera = setmetatable({
        x = options.x or 0, y = options.y or 0, z = options.z or 0,
        yaw = options.yaw or 0, pitch = 0,
        fov = options.fov, near = options.near, far = options.far,
    }, Camera)
    camera:rotate(0, options.pitch or 0)
    return camera
end

--- Unit view direction.
--- @return number x, number y, number z
function Camera:forward()
    local cosPitch = math.cos(self.pitch)
    return cosPitch * math.cos(self.yaw), cosPitch * math.sin(self.yaw), math.sin(self.pitch)
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
    local fx, fy, fz = self:forward()
    local rx, ry = math.sin(self.yaw), -math.cos(self.yaw)
    local vx = fx * forward + rx * right
    local vy = fy * forward + ry * right
    local vz = fz * forward + up
    local length = math.sqrt(vx * vx + vy * vy + vz * vz)
    if length > 0 then
        local scale = speed * dt / length
        self.x, self.y, self.z = self.x + vx * scale, self.y + vy * scale, self.z + vz * scale
    end
end

--- @param aspect number Viewport width / height.
--- @return Mat4
function Camera:viewProjection(aspect)
    local fx, fy, fz = self:forward()
    local view = Mat4.lookAlong(self.x, self.y, self.z, fx, fy, fz, 0, 0, 1)
    return Mat4.multiply(Mat4.perspective(self.fov, aspect, self.near, self.far), view)
end

return Camera
