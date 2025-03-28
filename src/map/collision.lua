local pos = require("src.base.pos")

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

---Check if a tile exists and is walkable at the given coordinates
---@param x number The x coordinate
---@param y number The y coordinate
---@return boolean walkable Whether the tile exists and is walkable
local function is_walkable_at(x, y)
    if y < 1 or y > collision.map.height or x < 1 or x > collision.map.width then
        return false
    end
    local tile = collision.map.layers[1].data[y][x]
    return tile and collision.walkable_tiles[tile.gid] or false
end

---Find tiles that should be in the overlap layer (non-walkable tiles with walkable tiles nearby)
---@return table[] Array of {x: number, y: number, tile: table} entries
function collision.find_overlap_layer_tiles()
    local overlapping_tiles = {}
    
    -- Directions to check for walkable tiles (relative to current tile)
    local directions = {
        {dx = 0, dy = -1},  -- above
        {dx = -1, dy = 0},  -- left
        {dx = 1, dy = 0},   -- right
        {dx = -1, dy = -1}, -- left-up
        {dx = 1, dy = -1},  -- right-up
    }
    
    for y = 1, collision.map.height do
        for x = 1, collision.map.width do
            local tile = collision.map.layers[1].data[y][x]
            if tile and not collision.walkable_tiles[tile.gid] then
                -- First check if tile below is NOT walkable (exclusion rule)
                if not is_walkable_at(x, y + 1) then
                    -- Then check all neighbor directions
                    for _, dir in ipairs(directions) do
                        if is_walkable_at(x + dir.dx, y + dir.dy) then
                            table.insert(overlapping_tiles, {
                                x = x,
                                y = y,
                                tile = tile
                            })
                            -- Break inner loop once we find any walkable neighbor
                            break
                        end
                    end
                end
            end
        end
    end
    return overlapping_tiles
end

---Initialize the collision system
---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function collision.load(opts)
    opts = opts or { reset = true }

    if opts.reset then
        -- Reset state
        collision.walkable_tiles = {}
        collision.map = _game.dungeon.map
        collision.process_walkable_tiles()

        -- Create overlap layer with found tiles
        local overlapping_tiles = collision.find_overlap_layer_tiles()
        _game.dungeon.make_overlap_layer(overlapping_tiles)
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
---@param buffer pos? The buffer zone size in tile space (default: pos(0.4, 0.2))
---@return boolean walkable Whether the position is walkable
function collision.is_walkable(x, y, buffer)
    -- Default buffer zone in tile space
    buffer = buffer or pos.new(0.4, 0.2)

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

return collision 