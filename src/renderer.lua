--- Draws the world as one mesh per chunk, rebuilding chunks when blocks change.

local Blocks = require("src.blocks")
local Extent3 = require("src.math.extent3")
local Mesher = require("src.mesher")

--- @class RendererOptions
--- @field chunkSize integer Chunk edge length in blocks.
--- @field textureDir string Folder holding Blocks.TEXTURES.

--- @class Renderer
--- @field world World
--- @field chunkSize integer
--- @field chunks Extent3 World size in chunks; chunk keys are `chunks:index(cx, cy, cz)`.
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
        chunks = Extent3.new(
            math.ceil(world.size.x / size), math.ceil(world.size.y / size), math.ceil(world.size.z / size)),
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
--- @param cx integer
--- @param cy integer
--- @param cz integer
function Renderer:markChunkDirty(cx, cy, cz)
    if self.chunks:contains(cx, cy, cz) then
        self.dirty[self.chunks:index(cx, cy, cz)] = true
    end
end

--- Call after changing the block at `block`. Also refreshes neighboring
--- chunks when the block sits on a chunk border, since their faces may change.
--- @param block Vec3 Integer block coordinates.
function Renderer:blockChanged(block)
    local x, y, z = block.x, block.y, block.z
    local size = self.chunkSize
    local cx, cy, cz = math.floor(x / size), math.floor(y / size), math.floor(z / size)
    local lx, ly, lz = x % size, y % size, z % size
    self:markChunkDirty(cx, cy, cz)
    if lx == 0 then self:markChunkDirty(cx - 1, cy, cz) end
    if lx == size - 1 then self:markChunkDirty(cx + 1, cy, cz) end
    if ly == 0 then self:markChunkDirty(cx, cy - 1, cz) end
    if ly == size - 1 then self:markChunkDirty(cx, cy + 1, cz) end
    if lz == 0 then self:markChunkDirty(cx, cy, cz - 1) end
    if lz == size - 1 then self:markChunkDirty(cx, cy, cz + 1) end
end

--- @param key integer See Renderer.chunks.
function Renderer:rebuildChunk(key)
    local cx, cy, cz = self.chunks:cell(key)
    local size = self.chunkSize

    if self.meshes[key] then
        self.meshes[key]:release()
        self.meshes[key] = nil
    end
    local vertices = Mesher.buildChunk(self.world, cx * size, cy * size, cz * size, size)
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
