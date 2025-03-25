local STI = require("src/libraries/sti.init")
local Vector2 = require("src.vector2")

-- Constants
local TILE_SIZE = 32
local OBJECTS_LAYER_ID = 2

---@class MapManager
---@field map table
---@field player_tile_id number
---@field tile_center Vector2
---@field map_size Vector2
---@field walkable_tiles table<number, boolean>
---@field enemies table<number, {hitpoints: number}>
---@field weapons table<number, {attack_type: string, melee_damage: number, speed: number, initial: boolean, tile: table, cooldown: number}>
---@field shields table<number, {amount: number}>
---@field chest_anim number[] Array of tile IDs for chest animation frames
local map_manager = {
    map = nil,
    player_tile_id = nil,
    tile_center = Vector2.new(0, 0),
    map_size = Vector2.new(0, 0),
    walkable_tiles = {},
    enemies = {},
    weapons = {},
    shields = {},
    chest_anim = {}
}

function map_manager.find_player_tile_id()
    local found_tile_id = nil
    for gid, tile in pairs(map_manager.map.tiles) do
        if tile.properties and tile.properties["kind"] == "player" then
            found_tile_id = gid
        end
    end
    assert(found_tile_id ~= nil, "No player tile found in map! Make sure there is a tile with property 'kind' set to 'player'")
    return found_tile_id
end

---@class TileLocation
---@field x number
---@field y number
---@field tile table
---@return TileLocation|nil
function map_manager.find_tile_by_id(tile_id)
    assert(map_manager.map ~= nil, "Map not loaded! This should never happen as we verify the map exists before calling this function.")
    
    local objects_layer = map_manager.map.layers[OBJECTS_LAYER_ID]
    for y = 1, objects_layer.height do
        for x = 1, objects_layer.width do
            local tile = objects_layer.data[y][x]
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

function map_manager.load()
    -- Load the map
    map_manager.map = STI("assets/maps/level1.lua")
    print("Map loaded:", map_manager.map.width, "x", map_manager.map.height)
    
    -- Find player tile ID in the Objects layer
    map_manager.player_tile_id = map_manager.find_player_tile_id()
    
    -- Calculate tile center once
    map_manager.tile_center = Vector2.new(map_manager.map.tilewidth/2, map_manager.map.tileheight/2)
    
    -- Calculate map size once
    map_manager.map_size = Vector2.new(
        map_manager.map.width * map_manager.map.tilewidth,
        map_manager.map.height * map_manager.map.tileheight
    )

    -- Process all tiles and their properties
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
            print(string.format("  Has kind: %s", props["kind"]))
            if props["kind"] == "enemy" then
                map_manager.enemies[gid] = {
                    hitpoints = props["hitpoints"] or 100
                }
            elseif props["kind"] == "weapon" then
                map_manager.weapons[gid] = {
                    attack_type = props.attack_type,
                    melee_damage = props.melee_damage,
                    speed = props.speed,
                    initial = props.initial or false,
                    cooldown = props.cooldown or 0,  -- Default to 0 if not specified
                    tile = tile  -- Store tile data for rendering
                }
            elseif props["kind"] == "shield" then
                map_manager.shields[gid] = {
                    amount = props["amount"] or 0
                }
            elseif props["kind"] == "chest" then
                -- Store chest animation frames in order
                local anim_frame = props["anim"] or 0
                map_manager.chest_anim[anim_frame + 1] = gid
            end
        end

        ::continue::
    end

    -- Hide the Objects layer
    map_manager.map.layers[OBJECTS_LAYER_ID].visible = false

    -- Print debug information about processed tiles
    _game.debug.print_map_tiles()
end

---Check if a tile position is walkable (with buffer zone for movement)
---@param x number The x coordinate in tile space
---@param y number The y coordinate in tile space
---@return boolean walkable Whether the tile at (x,y) is walkable
function map_manager.is_walkable(x, y)
    -- Add buffer zone in tile space
    local buffer = 0.4
    
    -- Check all corners of the player's collision box
    local points_to_check = {
        {x = x - buffer, y = y - buffer}, -- Top left
        {x = x + buffer, y = y - buffer}, -- Top right
        {x = x - buffer, y = y + buffer}, -- Bottom left
        {x = x + buffer, y = y + buffer}  -- Bottom right
    }
    
    for _, point in ipairs(points_to_check) do
        local tile_x = math.floor(point.x)
        local tile_y = math.floor(point.y)
        
        -- Check map boundaries
        if tile_x < 1 or tile_x > map_manager.map.width or 
           tile_y < 1 or tile_y > map_manager.map.height then
            return false
        end
        
        -- Get the tile at this position from the first layer
        local tile = map_manager.map.layers[1].data[tile_y][tile_x]
        if not tile or not map_manager.walkable_tiles[tile.gid] then
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

---Draw walls that should appear above the player
---@param player_pos Vector2 The player's current position
function map_manager.draw_walls_above_player(player_pos)
    local player_x = math.floor(player_pos.x)
    local player_y = math.floor(player_pos.y)
    
    -- Check the two tiles below the player
    for dx = 0, 1 do
        local tile_x = player_x + dx
        local tile_y = player_y + 1
        
        -- If this is a non-walkable tile (wall), redraw it
        if not map_manager.is_walkable_tile(tile_x, tile_y) then
            local tile = map_manager.map.layers[1].data[tile_y][tile_x]
            if tile then
                local tileset = map_manager.map.tilesets[tile.tileset]
                -- Ensure pixel-perfect alignment by snapping to tile grid
                local screen_x = (tile_x - 1) * map_manager.map.tilewidth
                local screen_y = (tile_y - 1) * map_manager.map.tileheight
                love.graphics.draw(tileset.image, tile.quad, screen_x, screen_y)
            end
        end
    end
end

-- Add map manager to global game variable when loaded
_game = _game or {}
_game.map_manager = map_manager

return map_manager 