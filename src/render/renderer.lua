--- Draws the world as one mesh per chunk, rebuilding chunks when blocks change.

local Blocks = require("src.world.blocks")
local Mesher = require("src.render.mesher")
local Vec3 = require("src.math.vec3")

--- @class RendererOptions
--- @field chunkSize integer Chunk edge length in blocks.
--- @field textureDir string Folder holding Blocks.TEXTURES.

--- @class Renderer
--- @field world World
--- @field chunkSize integer
--- @field chunks Extent3 World size in chunks; chunk keys are `chunks:index(chunk)`.
--- @field shader love.Shader
--- @field textures love.Image Array image, one layer per Blocks.TEXTURES entry.
--- @field meshes table<integer, love.Mesh> Chunk key -> mesh (absent for empty chunks).
--- @field dirty table<integer, true> Chunk keys to rebuild on the next update.
local Renderer = {}
Renderer.__index = Renderer

local VERTEX_FORMAT = {
    { "VertexPosition", "float", 3 },
    { "VertexTexCoord", "float", 3 }, -- u, v, array texture layer
    { "VertexColor", "byte", 4 },
}

local VERTEX_SHADER = [[
uniform mat4 viewProjection;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return viewProjection * vertexPosition;
}
]]

-- Samples layer VaryingTexCoord.z of an array texture.
local PIXEL_SHADER = [[
uniform ArrayImage MainTex;

void effect() {
    love_PixelColor = Texel(MainTex, VaryingTexCoord.xyz) * VaryingColor;
}
]]

--- @param world World
--- @param options RendererOptions
--- @return Renderer
function Renderer.new(world, options)
    local paths = {}
    for i, name in ipairs(Blocks.TEXTURES) do
        paths[i] = options.textureDir .. "/" .. name
    end
    -- Browsers need WebGL 2, which the love.js build in tools/build_web.sh provides.
    assert(love.graphics.getTextureTypes()["array"], "array textures are not supported (WebGL 2 is required)")
    local textures = love.graphics.newArrayImage(paths, { mipmaps = true })
    textures:setFilter("linear", "nearest")
    textures:setMipmapFilter("linear")

    local size = options.chunkSize
    local self = setmetatable({
        world = world,
        chunkSize = size,
        chunks = world.size:divideRoundingUp(size),
        shader = love.graphics.newShader(PIXEL_SHADER, VERTEX_SHADER),
        textures = textures,
        meshes = {},
        dirty = {},
    }, Renderer)

    for key = 0, self.chunks:volume() - 1 do
        self.dirty[key] = true
    end
    return self
end

--- Queues a chunk for rebuilding; out-of-range chunks are ignored.
--- @param chunk Vec3 Chunk coordinates (block coordinates / chunk size).
function Renderer:markChunkDirty(chunk)
    if self.chunks:contains(chunk) then
        self.dirty[self.chunks:index(chunk)] = true
    end
end

--- The chunks whose meshes can change when `block` changes: its own chunk, plus
--- each neighboring chunk it shares a face with (when it sits on a chunk border,
--- the neighbor's face against it may appear or disappear). May include chunks
--- outside the world.
--- @param block Vec3 Integer block coordinates.
--- @param chunkSize integer
--- @return Vec3[] Chunk coordinates.
function Renderer.chunksTouching(block, chunkSize)
    local chunk = (block / chunkSize):floor()
    local inChunk = block - chunk * chunkSize -- 0..chunkSize-1 on each axis
    local chunks = { chunk }
    for _, axis in ipairs(Vec3.AXES) do
        if inChunk[axis] == 0 then
            chunks[#chunks + 1] = chunk - Vec3.unit(axis)
        end
        if inChunk[axis] == chunkSize - 1 then
            chunks[#chunks + 1] = chunk + Vec3.unit(axis)
        end
    end
    return chunks
end

--- Call after changing the block at `block`, to rebuild the affected chunks.
--- @param block Vec3 Integer block coordinates.
function Renderer:blockChanged(block)
    for _, chunk in ipairs(Renderer.chunksTouching(block, self.chunkSize)) do
        self:markChunkDirty(chunk)
    end
end

--- @param key integer See Renderer.chunks.
function Renderer:rebuildChunk(key)
    local chunk = self.chunks:cell(key)
    local size = self.chunkSize

    if self.meshes[key] then
        self.meshes[key]:release()
        self.meshes[key] = nil
    end
    local vertices = Mesher.buildChunk(self.world, chunk * size, size)
    if #vertices > 0 then
        local mesh = love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
        mesh:setTexture(self.textures)
        self.meshes[key] = mesh
    end
end

--- Rebuilds every chunk marked dirty since the last update.
function Renderer:update()
    for key in pairs(self.dirty) do
        self:rebuildChunk(key)
    end
    self.dirty = {}
end

--- @param viewProjection Mat4 From Camera:viewProjection.
function Renderer:draw(viewProjection)
    love.graphics.push("all")
    love.graphics.setShader(self.shader)
    self.shader:send("viewProjection", "row", viewProjection)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("back")
    for _, mesh in pairs(self.meshes) do
        love.graphics.draw(mesh)
    end
    love.graphics.pop()
end

return Renderer
