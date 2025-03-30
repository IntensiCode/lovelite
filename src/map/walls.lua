local walls = {}

-- Store full_wall_tiles for efficient access
walls.full_wall_tiles = {}

---Check if a tile is a full wall based on its local 3x3 neighborhood
---@param x integer The x coordinate to check
---@param y integer The y coordinate to check
---@return boolean is_full_wall Whether the tile is a full wall
function walls.is_full_wall_tile(x, y)
    -- Check map boundaries - required to avoid errors
    if x < 1 or x > DI.dungeon.map.width or y < 1 or y > DI.dungeon.map.height then
        return false
    end

    -- Check if this tile is a wall (non-walkable)
    local is_walkable = DI.collision.is_walkable_tile(x, y)
    if is_walkable then
        return false
    end

    -- Check if the tile below is walkable (floor)
    local below_walkable = DI.collision.is_walkable_tile(x, y + 1)
    if not below_walkable then
        return false
    end

    -- Check for counter examples - no wall on left or right
    local left_is_wall = not DI.collision.is_walkable_tile(x - 1, y)
    local right_is_wall = not DI.collision.is_walkable_tile(x + 1, y)

    -- For counter example 1: No wall to the left
    if not left_is_wall and right_is_wall then
        return false
    end

    -- For counter example 2: No wall to the right
    if left_is_wall and not right_is_wall then
        return false
    end

    -- Always return true if we have a wall with walkable tile below it
    -- This meets the basic specification - any wall with a walkable tile below it
    local is_full_wall = true

    -- If we're running in debug mode, output more information
    if os.getenv("DEBUG") then
        log.debug(string.format("Wall check at (%d,%d): Below walkable=%s, Full=%s",
            x, y,
            tostring(DI.collision.is_walkable_tile(x, y + 1)),
            tostring(is_full_wall)))
    end

    return is_full_wall
end

---Identify all full wall tiles in the map
---@return table<string, boolean> Map of "x,y" coordinates to full wall status
function walls.identify_full_wall_tiles()
    local full_wall_tiles = {}

    local map = DI.dungeon.map
    log.debug("Starting full wall detection, map size:", map.width, "x", map.height)

    -- Apply our 3x3 pattern matching across the entire map
    for y = 1, map.height do
        for x = 1, map.width do
            if walls.is_full_wall_tile(x, y) then
                local key = x .. "," .. y
                full_wall_tiles[key] = true
            end
        end
    end

    -- Store the results in our module
    walls.full_wall_tiles = full_wall_tiles
    log.debug("Full wall tiles identified:", table.count(full_wall_tiles))

    return full_wall_tiles
end

---Check if coordinates represent a full wall tile
---@param x integer The x coordinate
---@param y integer The y coordinate
---@return boolean is_full_wall Whether the coordinates represent a full wall tile
function walls.check_full_wall(x, y)
    -- If the full_wall_tiles table isn't initialized yet, do it now
    if next(walls.full_wall_tiles) == nil then
        walls.identify_full_wall_tiles()
    end

    local key = x .. "," .. y
    return walls.full_wall_tiles[key] or false
end

return walls
