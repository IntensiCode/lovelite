local STI = require("src.libraries.sti.init")
local Vector2 = require("src.base.vector2")
local table_utils = require("src.base.table")

-- Constants
local OBJECTS_LAYER_ID = 2

---@class MapManager
---@field map table The STI map object
---@field tile_center Vector2 The center position of the current tile
---@field map_size Vector2 The size of the map in tiles
---@field enemies table<number, {hitpoints: number, armorclass: number, tile: table, armorclass: number, hitpoints: number, max_hitpoints: number}>
---@field weapons table<number, {name: string, melee: number, speed: number, initial: boolean, tile: table, cooldown: number}>
---@field shields table<number, {name: string, tile: table, armorclass: number, hitpoints: number, max_hitpoints: number}>
---@field chest_anim number[] Array of tile IDs for chest animation frames
---@field objects_layer table The layer containing game objects
---@field player {hitpoints: number, armorclass: number, tile: table, max_hitpoints: number, armorclass: number, hitpoints: number, speed: number, weapon: string}
local map_manager = {
    map = nil,
    tile_center = Vector2.new(0, 0),
    map_size = Vector2.new(0, 0),
    enemies = {},
    weapons = {},
    shields = {},
    chest_anim = {},
    objects_layer = nil,
    player = nil
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
    local location = map_manager.find_tile_by_id(map_manager.find_player_tile_id())
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

        -- Process by kind
        if props["kind"] then
            -- print(string.format("  Has kind: %s", props["kind"]))
            if props["kind"] == "enemy" then
                map_manager.enemies[gid] = table_utils.clone(props)
                map_manager.enemies[gid].max_hitpoints = map_manager.enemies[gid].hitpoints
                map_manager.enemies[gid].tile = tile
            elseif props["kind"] == "weapon" then
                map_manager.weapons[gid] = table_utils.clone(props)
                map_manager.weapons[gid].tile = tile
            elseif props["kind"] == "shield" then
                map_manager.shields[gid] = table_utils.clone(props)
                map_manager.shields[gid].max_hitpoints = map_manager.shields[gid].hitpoints
                map_manager.shields[gid].tile = tile
            elseif props["kind"] == "chest" then
                -- Store chest animation frames in order
                local anim_frame = props["anim"] or 0
                map_manager.chest_anim[anim_frame + 1] = gid
            elseif props["kind"] == "player" then
                map_manager.player = table_utils.clone(props)
                map_manager.player.max_hitpoints = map_manager.player.hitpoints
                map_manager.player.tile = tile
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
