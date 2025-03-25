local Vector2 = require("src.vector2")

---@class Collectible
---@field pos Vector2
---@field tile table
---@field properties table
---@field hover_offset number
---@field hover_time number
local collectibles = {
    items = {},
    hover_offset = 2.5,  -- How much to hover up/down
    hover_speed = 2.5,     -- Speed of hover animation
}

function collectibles.load()
    -- Get the Objects layer
    local objects_layer = _game.map_manager.get_objects_layer()
    
    -- Process each tile in the Objects layer
    for y = 1, objects_layer.height do
        for x = 1, objects_layer.width do
            local tile = _game.map_manager.get_objects_tile(x, y)
            if tile and tile.properties and tile.properties["kind"] == "weapon" then
                -- Create a collectible for this weapon tile
                table.insert(collectibles.items, {
                    pos = Vector2.new(x, y),
                    tile = tile,
                    properties = tile.properties,
                    hover_offset = 0,
                    hover_time = math.random() * 2 * math.pi
                })
            end
        end
    end
end

function collectibles.update(dt)
    -- Update hover animation for each collectible
    for _, item in ipairs(collectibles.items) do
        item.hover_time = item.hover_time + dt
        item.hover_offset = math.sin(item.hover_time * collectibles.hover_speed) * collectibles.hover_offset
    end
end

function collectibles.draw()
    for _, item in ipairs(collectibles.items) do
        -- Convert tile position to screen position
        local screen_x = ((item.pos.x - 1) * _game.map_manager.map.tilewidth)
        local screen_y = ((item.pos.y - 1) * _game.map_manager.map.tileheight)
        
        -- Get tile dimensions
        local _, _, tile_width, tile_height = item.tile.quad:getViewport()

        -- Draw a dark gray circle below as pseudo-shadow
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.circle("fill", screen_x + tile_width/2, screen_y + tile_height, 3)
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Draw collectible centered
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            item.tile.quad,
            screen_x,
            screen_y + item.hover_offset,
            0,
            1, 1
        )
    end
end

-- Add collectibles to global game variable when loaded
_game = _game or {}
_game.collectibles = collectibles

return collectibles 