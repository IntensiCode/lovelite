local Vector2 = require("src.base.vector2")

---@class Collision
---@field walkable_tiles table<number, boolean> Map of tile IDs to walkable status
---@field map table The STI map object
local collision = {
    walkable_tiles = {},
    map = nil
}

-- Make collision available globally right away
_game = _game or {}
_game.collision = collision

---Initialize the collision system
---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function collision.load(opts)
    opts = opts or { reset = true }

    if opts.reset then
        -- Reset state
        collision.walkable_tiles = {}
        collision.map = _game.dungeon.map
        collision.process_walkable_tiles()
    end
end

---Process walkable tiles from the map
function collision.process_walkable_tiles()
    assert(collision.map, "Map must be loaded before processing walkable tiles")
    collision.walkable_tiles = {}
    for gid, tile in pairs(collision.map.tiles) do
        local props = tile.properties
        if props and props["walkable"] == true then
            collision.walkable_tiles[gid] = true
        end
    end
end

---Check if a specific tile is walkable (without buffer zone)
---@param x integer The tile x coordinate
---@param y integer The tile y coordinate
---@return boolean walkable Whether the tile at (x,y) is walkable
function collision.is_walkable_tile(x, y)
    -- Check map boundaries
    if x < 1 or x > collision.map.width or y < 1 or y > collision.map.height then
        return false
    end

    -- Get the tile at this position from the first layer
    local tile = collision.map.layers[1].data[y][x]
    if not tile then return false end

    -- Check if the tile's gid is in our walkable_tiles table
    return collision.walkable_tiles[tile.gid] or false
end

---Check if a position is walkable (with buffer zone for movement)
---@param x number The x coordinate in tile space
---@param y number The y coordinate in tile space
---@param buffer Vector2? The buffer zone size in tile space (default: Vector2(0.4, 0.2))
---@return boolean walkable Whether the position is walkable
function collision.is_walkable(x, y, buffer)
    -- Default buffer zone in tile space
    buffer = buffer or Vector2.new(0.4, 0.2)

    -- Check all corners of the entity's collision box
    local points_to_check = {
        { x = x - buffer.x, y = y - buffer.y }, -- Top left
        { x = x + buffer.x, y = y - buffer.y }, -- Top right
        { x = x - buffer.x, y = y + buffer.y }, -- Bottom left
        { x = x + buffer.x, y = y + buffer.y }  -- Bottom right
    }

    for _, point in ipairs(points_to_check) do
        local tile_x = math.floor(point.x)
        local tile_y = math.floor(point.y)
        if not collision.is_walkable_tile(tile_x, tile_y) then
            return false
        end
    end

    return true
end

---Find all walkable tiles directly adjacent to the given position
---@param tile_x number The x coordinate in tile space
---@param tile_y number The y coordinate in tile space
---@return table[] Array of {x: number, y: number} positions of walkable tiles
function collision.find_walkable_around(tile_x, tile_y)
    local walkable_tiles = {}
    local directions = {
        {dx = -1, dy = 0},  -- left
        {dx = 1, dy = 0},   -- right
        {dx = 0, dy = -1},  -- up
        {dx = 0, dy = 1},   -- down
        {dx = -1, dy = -1}, -- up-left
        {dx = 1, dy = -1},  -- up-right
        {dx = -1, dy = 1},  -- down-left
        {dx = 1, dy = 1}    -- down-right
    }

    for _, dir in ipairs(directions) do
        local check_x = tile_x + dir.dx
        local check_y = tile_y + dir.dy
        if collision.is_walkable_tile(check_x, check_y) then
            table.insert(walkable_tiles, {x = check_x, y = check_y})
        end
    end

    return walkable_tiles
end

---Check a single offset position for overlapping tiles
---@param pos_x number The entity's x position in tile space
---@param pos_y number The entity's y position in tile space
---@param offset table The offset to check {dx: number, dy: number}
---@return table|nil The tile data and screen position if found, nil otherwise
local function check_offset_position(pos_x, pos_y, offset)
    local tile_x = pos_x + offset.dx
    local tile_y = pos_y + offset.dy

    -- If this is a non-walkable tile (wall), add it to the result
    if not collision.is_walkable_tile(tile_x, tile_y) then
        local tile = collision.map.layers[1].data[tile_y][tile_x]
        if tile then
            -- Calculate screen position
            local screen_x = math.floor((tile_x - 1) * collision.map.tilewidth) - 0.5
            local screen_y = math.floor((tile_y - 1) * collision.map.tileheight) - 0.5
            return { tile = tile, screen_x = screen_x, screen_y = screen_y }
        end
    end
    return nil
end

---Find tiles that should appear above the given positions
---@param positions Vector2[] List of positions to check
---@return table[] List of {tile, screen_x, screen_y} tuples
function collision.find_overlapping_tiles(positions)
    local result = {}

    -- List of (dx,dy) offsets to check
    local offsets = {
        { dx = -1, dy = 0 },
        { dx = -1, dy = 1 },
        { dx = 0,  dy = 1 },
        { dx = 1,  dy = 1 }
    }

    for _, pos in ipairs(positions) do
        local pos_x = math.floor(pos.x)
        local pos_y = math.floor(pos.y)

        -- Check each offset
        for _, offset in ipairs(offsets) do
            local tile_data = check_offset_position(pos_x, pos_y, offset)
            if tile_data then
                table.insert(result, tile_data)
            end
        end
    end

    return result
end

---Draw tiles that should appear above entities
---@param tiles table[] List of {tile, screen_x, screen_y} tuples
function collision.draw_overlapping_tiles(tiles)
    for _, data in ipairs(tiles) do
        local tileset = collision.map.tilesets[data.tile.tileset]
        love.graphics.draw(tileset.image, data.tile.quad, data.screen_x, data.screen_y)
    end
end

return collision 