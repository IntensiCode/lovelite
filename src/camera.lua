local Vector2 = require("src.base.vector2")

---@class Camera
---@field canvas love.Canvas
---@field width number
---@field height number
---@field scale number
---@field offset Vector2
---@field virtual_center Vector2
---@field world_pos Vector2
---@field pos Vector2
---@field target Vector2
---@field zoom number
---@field loaded boolean
local camera = {
    canvas = nil,
    width = 320,  -- Base virtual width
    height = 200, -- Base virtual height
    scale = 1,
    offset = Vector2.new(0, 0),
    virtual_center = Vector2.new(0, 0),
    world_pos = Vector2.new(0, 0),
    pos = Vector2.new(0, 0),
    target = Vector2.new(0, 0),
    zoom = 1,
    loaded = false
}

function camera.load()
    -- Return early if already loaded
    if camera.loaded then return end

    -- Set initial camera position
    camera.pos = Vector2.new(0, 0)
    camera.target = Vector2.new(0, 0)
    camera.zoom = 1

    -- Set up window
    love.window.setMode(1600, 1200, {
        resizable = true,
        minwidth = camera.width,
        minheight = camera.height
    })

    -- Set up canvas for virtual resolution with pixel-perfect scaling
    love.graphics.setDefaultFilter('nearest', 'nearest')
    camera.canvas = love.graphics.newCanvas(camera.width, camera.height)

    -- Calculate initial scaling
    camera.updateScaling()

    -- Calculate initial virtual center
    camera.virtual_center = Vector2.new(camera.width / 2, camera.height / 2)

    -- Initialize camera position to player's starting position
    assert(_game.player ~= nil, "Player must exist before camera is loaded")
    assert(_game.player.pos ~= nil, "Player must have a position before camera is loaded")
    camera.world_pos = _game.player.pos

    -- Mark as loaded
    camera.loaded = true
end

function camera.update(dt)
    -- Safety check for player and position
    assert(_game.player ~= nil, "Player must exist for camera update")
    assert(_game.player.pos ~= nil, "Player must have a position for camera update")

    -- Get map dimensions in tiles
    local map_width = _game.dungeon.map.width
    local map_height = _game.dungeon.map.height
    local virtual_width, virtual_height = camera.getDimensions()

    -- Calculate camera position to center on player
    camera.world_pos = _game.player.pos
end

function camera.updateScaling()
    local window_width, window_height = love.graphics.getDimensions()
    local scale_x = window_width / camera.width
    local scale_y = window_height / camera.height
    camera.scale = math.min(scale_x, scale_y)

    camera.offset = Vector2.new(
        (window_width - (camera.width * camera.scale)) / 2,
        (window_height - (camera.height * camera.scale)) / 2
    )
end

function camera.beginDraw()
    love.graphics.setCanvas(camera.canvas)
    love.graphics.clear(0.1, 0.1, 0.1, 1)
end

function camera.endDraw()
    -- Reset canvas
    love.graphics.setCanvas()

    -- Draw the canvas scaled to fit the window with pixel-perfect scaling
    love.graphics.setBlendMode('replace', 'premultiplied')
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        camera.canvas,
        camera.offset.x, camera.offset.y,
        0,
        camera.scale, camera.scale
    )
    love.graphics.setBlendMode('alpha')
end

function camera.resize(w, h)
    -- Calculate scale to fit window while maintaining aspect ratio
    local scale_x = w / camera.width
    local scale_y = h / camera.height
    camera.scale = math.min(scale_x, scale_y)

    -- Calculate offsets to center the virtual resolution
    camera.offset = Vector2.new(
        (w - camera.width * camera.scale) / 2,
        (h - camera.height * camera.scale) / 2
    )

    -- Update virtual center
    camera.virtual_center = Vector2.new(camera.width / 2, camera.height / 2)
end

function camera.getDimensions()
    return camera.width, camera.height
end

---@return Vector2
function camera.translation()
    -- Convert player position (in tiles) to pixels and center the view
    return Vector2.new(
        -(camera.world_pos.x * _game.dungeon.map.tilewidth) + (camera.width / 2),
        -(camera.world_pos.y * _game.dungeon.map.tileheight) + (camera.height / 2)
    )
end

-- Add camera to global game variable when loaded
_game = _game or {}
_game.camera = camera

return camera
