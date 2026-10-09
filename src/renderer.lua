--- Draws the world as one mesh per chunk, rebuilding chunks when blocks change.

local Blocks = require("src.blocks")
local Mesher = require("src.mesher")

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

--- @param world table See src/world.lua.
--- @param options table `{ chunkSize, textureDir }`
--- @return table
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
        chunksX = math.ceil(world.sizeX / size),
        chunksY = math.ceil(world.sizeY / size),
        chunksZ = math.ceil(world.sizeZ / size),
        shader = love.graphics.newShader(PIXEL_SHADER, VERTEX_SHADER),
        textures = textures,
        meshes = {}, -- chunk key -> Mesh (absent for empty chunks)
        dirty = {}, -- chunk key -> true
    }, Renderer)

    for cz = 0, self.chunksZ - 1 do
        for cy = 0, self.chunksY - 1 do
            for cx = 0, self.chunksX - 1 do
                self:markChunkDirty(cx, cy, cz)
            end
        end
    end
    return self
end

function Renderer:markChunkDirty(cx, cy, cz)
    if cx >= 0 and cy >= 0 and cz >= 0 and cx < self.chunksX and cy < self.chunksY and cz < self.chunksZ then
        self.dirty[cx + self.chunksX * (cy + self.chunksY * cz)] = true
    end
end

--- Call after changing the block at (x, y, z). Also refreshes neighboring
-- chunks when the block sits on a chunk border, since their faces may change.
function Renderer:blockChanged(x, y, z)
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

function Renderer:rebuildChunk(key)
    local cx = key % self.chunksX
    local cy = math.floor(key / self.chunksX) % self.chunksY
    local cz = math.floor(key / (self.chunksX * self.chunksY))
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

--- @param viewProjection table Row-major matrix from Camera:viewProjection.
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
