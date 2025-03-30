local pos = require("src.base.pos")

---@class Camera
---@field canvas love.Canvas
---@field width number
---@field height number
---@field scale number
---@field offset pos
---@field virtual_center pos
---@field world_pos pos
---@field pos pos
---@field target pos
---@field zoom number
---@field loaded boolean
local camera = {
    canvas = nil,
    width = 320,  -- Base virtual width
    height = 200, -- Base virtual height
    scale = 1,
    offset = pos.new(0, 0),
    virtual_center = pos.new(0, 0),
    world_pos = pos.new(0, 0),
    pos = pos.new(0, 0),
    target = pos.new(0, 0),
    zoom = 1,
    loaded = false
}

function camera.load(opts)
    opts = opts or { reset = true }

    -- One-time initialization
    if not camera.loaded then
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
        camera.virtual_center = pos.new(camera.width / 2, camera.height / 2)

        camera.loaded = true
    end

    -- State that should be reset
    if opts.reset then
        -- Reset camera position and zoom
        camera.pos = pos.new(0, 0)
        camera.target = pos.new(0, 0)
        camera.zoom = 1

        -- Initialize camera position to player's starting position if available
        if DI.player and DI.player.pos then
            camera.world_pos = DI.player.pos
        else
            -- Default to origin if no player exists (e.g. title screen)
            camera.world_pos = pos.new(0, 0)
        end
    end
end

function camera.update(_)
    -- Safety check for player and position
    log.assert(DI.player ~= nil, "Player must exist for camera update")
    log.assert(DI.player.pos ~= nil, "Player must have a position for camera update")

    -- Calculate camera position to center on player
    camera.world_pos = DI.player.pos
end

function camera.updateScaling()
    local window_width, window_height = love.graphics.getDimensions()
    local scale_x = window_width / camera.width
    local scale_y = window_height / camera.height
    camera.scale = math.min(scale_x, scale_y)

    camera.offset = pos.new(
        (window_width - (camera.width * camera.scale)) / 2,
        (window_height - (camera.height * camera.scale)) / 2
    )
end

function camera.beginDraw()
    love.graphics.setCanvas(camera.canvas)
    love.graphics.clear(0, 0, 0, 1)
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
    camera.offset = pos.new(
        (w - camera.width * camera.scale) / 2,
        (h - camera.height * camera.scale) / 2
    )

    -- Update virtual center
    camera.virtual_center = pos.new(camera.width / 2, camera.height / 2)
end

function camera.getDimensions()
    return camera.width, camera.height
end

---@return pos
function camera.translation()
    -- Convert player position (in tiles) to pixels and center the view
    return pos.new(
        math.floor(-(camera.world_pos.x * DI.dungeon.tile_size) + (camera.width / 2)),
        math.floor(-(camera.world_pos.y * DI.dungeon.tile_size) + (camera.height / 2))
    )
end

return camera
