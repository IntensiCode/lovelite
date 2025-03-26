local STI = require("src/libraries/sti.init")
local Vector2 = require("src.vector2")

-- Constants
local OBJECTS_LAYER_ID = 2

---@class MapManager
---@field map table The STI map object
---@field player_tile_id number The tile ID for the player
---@field tile_center Vector2 The center position of the current tile
---@field map_size Vector2 The size of the map in tiles
---@field walkable_tiles table<number, boolean> Map of tile IDs to walkable status
---@field enemies table<number, {hitpoints: number}>
---@field weapons table<number, {name: string, melee: number, speed: number, initial: boolean, tile: table, cooldown: number}>
---@field shields table<number, {name: string, armorclass: number, hitpoints: number, max_hitpoints: number}>
---@field chest_anim number[] Array of tile IDs for chest animation frames
---@field objects_layer table The layer containing game objects
local map_manager = {
    map = nil,
    player_tile_id = nil,
    tile_center = Vector2.new(0, 0),
    map_size = Vector2.new(0, 0),
    walkable_tiles = {},
    enemies = {},
    weapons = {},
    shields = {},
    chest_anim = {},
    objects_layer = nil
}

---Get the objects layer from the map
---@return table The objects layer
function map_manager.get_objects_layer()
    -- If the objects layer is not already cached, get it from the map
    if not map_manager.objects_layer then
        map_manager.objects_layer = map_manager.map.layers[OBJECTS_LAYER_ID]
    end
    return map_manager.objects_layer
end

---Get a tile from the objects layer at the specified coordinates
---@param x number The x coordinate in tile space
---@param y number The y coordinate in tile space
---@return table|nil The tile at the specified coordinates, or nil if not found
function map_manager.get_objects_tile(x, y)
    local objects_layer = map_manager.get_objects_layer()
    if x < 1 or x > objects_layer.width or y < 1 or y > objects_layer.height then
        return nil
    end
    return objects_layer.data[y][x]
end

---@return number The tile ID of the player tile
function map_manager.find_player_tile_id()
    local found_tile_id = nil
    for gid, tile in pairs(map_manager.map.tiles) do
        if tile.properties and tile.properties["kind"] == "player" then
            found_tile_id = gid
        end
    end
    assert(found_tile_id ~= nil,
        "No player tile found in map! Make sure there is a tile with property 'kind' set to 'player'")
    return found_tile_id
end

---@class TileLocation
---@field x number
---@field y number
---@field tile table
---@return TileLocation|nil
function map_manager.find_tile_by_id(tile_id)
    assert(map_manager.map ~= nil,
        "Map not loaded! This should never happen as we verify the map exists before calling this function.")

    local objects_layer = map_manager.get_objects_layer()
    for y = 1, objects_layer.height do
        for x = 1, objects_layer.width do
            local tile = map_manager.get_objects_tile(x, y)
            if tile and tile.gid == tile_id then
                return {
                    x = x,
                    y = y,
                    tile = tile
                }
            end
        end
    end
    return nil
end

---@class PlayerSetup
---@field pos Vector2
---@field tile table
---@return PlayerSetup
function map_manager.get_player_start_position()
    print("Looking for player tile with ID:", map_manager.player_tile_id)

    local location = map_manager.find_tile_by_id(map_manager.player_tile_id)
    assert(location ~= nil, "Player tile not found in map! This should never happen as we verified the tile exists.")

    -- Add 0.5 to center the player in the tile
    return {
        pos = Vector2.new(location.x + 0.5, location.y + 0.5),
        tile = location.tile
    }
end

---Process all tiles and their properties, populating the various tile type tables
---@return nil
function map_manager.process_tiles()
    print("\nProcessing tiles:")
    for gid, tile in pairs(map_manager.map.tiles) do
        local props = tile.properties
        if not props then
            goto continue
        end

        -- Store walkable tiles
        if props["walkable"] == true then
            map_manager.walkable_tiles[gid] = true
        end

        -- Process by kind
        if props["kind"] then
            -- print(string.format("  Has kind: %s", props["kind"]))
            if props["kind"] == "enemy" then
                map_manager.enemies[gid] = {
                    hitpoints = props["hitpoints"] or 100
                }
            elseif props["kind"] == "weapon" then
                map_manager.weapons[gid] = {
                    melee = props.melee,
                    fire = props.fire,
                    ice = props.ice,
                    name = props.name,
                    lightning = props.lightning,
                    speed = props.speed,
                    initial = props.initial or false,
                    cooldown = props.cooldown or 0, -- Default to 0 if not specified
                    tile = tile                     -- Store tile data for rendering
                }
            elseif props["kind"] == "shield" then
                map_manager.shields[gid] = {
                    tile = tile,
                    name = props.name,
                    armorclass = props.armorclass or 0,
                    hitpoints = props.hitpoints or 0,
                    max_hitpoints = props.hitpoints or 0  -- Store initial hitpoints as max
                }
            elseif props["kind"] == "chest" then
                -- Store chest animation frames in order
                local anim_frame = props["anim"] or 0
                map_manager.chest_anim[anim_frame + 1] = gid
            end
        end

        ::continue::
    end
end

---Load and initialize the map, processing all tiles and their properties
---@return nil
function map_manager.load()
    -- Load the map
    map_manager.map = STI("assets/maps/level1.lua")
    print("Map loaded:", map_manager.map.width, "x", map_manager.map.height)

    -- Find player tile ID in the Objects layer
    map_manager.player_tile_id = map_manager.find_player_tile_id()

    -- Calculate tile center once
    map_manager.tile_center = Vector2.new(map_manager.map.tilewidth / 2, map_manager.map.tileheight / 2)

    -- Calculate map size once
    map_manager.map_size = Vector2.new(
        map_manager.map.width * map_manager.map.tilewidth,
        map_manager.map.height * map_manager.map.tileheight
    )

    -- Process all tiles and their properties
    map_manager.process_tiles()

    -- Hide the Objects layer
    map_manager.map.layers[OBJECTS_LAYER_ID].visible = false

    -- Print debug information about processed tiles
    -- _game.debug.print_map_tiles()
end

---Check if a tile position is walkable (with buffer zone for movement)
---@param x number The x coordinate in tile space
---@param y number The y coordinate in tile space
---@param buffer Vector2 The buffer zone size in tile space (default: Vector2(0.4, 0.2))
---@return boolean walkable Whether the tile at (x,y) is walkable
function map_manager.is_walkable(x, y, buffer)
    -- Default buffer zone in tile space
    buffer = buffer or Vector2.new(0.4, 0.2)

    -- Check all corners of the player's collision box
    local points_to_check = {
        { x = x - buffer.x, y = y - buffer.y }, -- Top left
        { x = x + buffer.x, y = y - buffer.y }, -- Top right
        { x = x - buffer.x, y = y + buffer.y }, -- Bottom left
        { x = x + buffer.x, y = y + buffer.y }  -- Bottom right
    }

    for _, point in ipairs(points_to_check) do
        local tile_x = math.floor(point.x)
        local tile_y = math.floor(point.y)
        if not map_manager.is_walkable_tile(tile_x, tile_y) then
            return false
        end
    end

    return true
end

---Check if a specific tile is walkable (without buffer zone)
---@param x integer The tile x coordinate
---@param y integer The tile y coordinate
---@return boolean walkable Whether the tile at (x,y) is walkable
function map_manager.is_walkable_tile(x, y)
    -- Check map boundaries
    if x < 1 or x > map_manager.map.width or y < 1 or y > map_manager.map.height then
        return false
    end

    -- Get the tile at this position from the first layer
    local tile = map_manager.map.layers[1].data[y][x]
    if not tile then return false end

    -- Check if the tile's gid is in our walkable_tiles table
    return map_manager.walkable_tiles[tile.gid] or false
end

---Check a single offset position for overlapping tiles
---@param player_x number The player's x position in tile space
---@param player_y number The player's y position in tile space
---@param offset table The offset to check {dx: number, dy: number}
---@return table|nil The tile data and screen position if found, nil otherwise
local function check_offset_position(player_x, player_y, offset)
    local tile_x = player_x + offset.dx
    local tile_y = player_y + offset.dy

    -- If this is a non-walkable tile (wall), add it to the result
    if not map_manager.is_walkable_tile(tile_x, tile_y) then
        local tile = map_manager.map.layers[1].data[tile_y][tile_x]
        if tile then
            -- Calculate screen position
            local screen_x = math.floor((tile_x - 1) * map_manager.map.tilewidth) - 0.5
            local screen_y = math.floor((tile_y - 1) * map_manager.map.tileheight) - 0.5
            return { tile = tile, screen_x = screen_x, screen_y = screen_y }
        end
    end
    return nil
end

---Find tiles that should appear above the given positions
---@param positions Vector2[] List of positions to check
---@return table[] List of {tile, screen_x, screen_y} tuples
function map_manager.find_overlapping_tiles(positions)
    local result = {}

    -- List of (dx,dy) offsets to check
    local offsets = {
        { dx = -1, dy = 0 },
        { dx = -1, dy = 1 },
        { dx = 0,  dy = 1 },
        { dx = 1,  dy = 1 }
    }

    for _, pos in ipairs(positions) do
        local player_x = math.floor(pos.x)
        local player_y = math.floor(pos.y)

        -- Check each offset
        for _, offset in ipairs(offsets) do
            local tile_data = check_offset_position(player_x, player_y, offset)
            if tile_data then
                table.insert(result, tile_data)
            end
        end
    end

    return result
end

---Draw tiles that should appear above the player
---@param tiles table[] List of {tile, screen_x, screen_y} tuples
function map_manager.draw_overlapping_tiles(tiles)
    for _, data in ipairs(tiles) do
        local tileset = map_manager.map.tilesets[data.tile.tileset]
        love.graphics.draw(tileset.image, data.tile.quad, data.screen_x, data.screen_y)
    end
end

---Convert world coordinates to grid coordinates
---@param world_pos Vector2 World position
---@return number, number grid_x, grid_y Grid coordinates
function map_manager.world_to_grid(world_pos)
    local grid_x = math.floor(world_pos.x / map_manager.map.tilewidth)
    local grid_y = math.floor(world_pos.y / map_manager.map.tileheight)
    return grid_x, grid_y
end

---Convert grid coordinates to world coordinates
---@param grid_x number Grid X coordinate
---@param grid_y number Grid Y coordinate
---@return Vector2 world_pos World position
function map_manager.grid_to_world(grid_x, grid_y)
    return Vector2.new(
        grid_x * map_manager.map.tilewidth + map_manager.map.tilewidth / 2,
        grid_y * map_manager.map.tileheight + map_manager.map.tileheight / 2
    )
end

-- Add map manager to global game variable when loaded
_game = _game or {}
_game.map_manager = map_manager

return map_manager
