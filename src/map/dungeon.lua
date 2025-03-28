local STI = require("src.libraries.sti.init")
local pos = require("src.base.pos")

-- Constants
local BASE_LAYER_ID = 1
local OBJECTS_LAYER_ID = 2
local OVERLAP_LAYER_ID = 3

---@class Dungeon
---@field map table The STI map object
---@field map_size pos The size of the map in tiles
---@field tile_size integer The size of a tile in pixels (width and height are equal)
---@field enemies table<number, {hitpoints: number, armorclass: number, tile: table, armorclass: number, hitpoints: number, max_hitpoints: number}>
---@field weapons table<number, {name: string, melee: number, speed: number, initial: boolean, tile: table, cooldown: number}>
---@field shields table<number, {name: string, tile: table, armorclass: number, hitpoints: number, max_hitpoints: number}>
---@field chest_anim number[] Array of tile IDs for chest animation frames
---@field objects_layer table The layer containing game objects
---@field player {hitpoints: number, armorclass: number, tile: table, max_hitpoints: number, armorclass: number, hitpoints: number, speed: number, weapon: string}
local dungeon = {
    map = nil,
    map_size = pos.new(0, 0),
    tile_size = 0,
    enemies = {},
    weapons = {},
    shields = {},
    chest_anim = {},
    objects_layer = nil,
    player = nil
}

---Get the objects layer from the map
---@return table The objects layer
function dungeon.get_objects_layer()
    -- If the objects layer is not already cached, get it from the map
    if not dungeon.objects_layer then
        dungeon.objects_layer = dungeon.map.layers[OBJECTS_LAYER_ID]
    end
    return dungeon.objects_layer
end

---Get a tile from the objects layer at the specified coordinates
---@param x number The x coordinate in tile space
---@param y number The y coordinate in tile space
---@return table|nil The tile at the specified coordinates, or nil if not found
function dungeon.get_objects_tile(x, y)
    local objects_layer = dungeon.get_objects_layer()
    if x < 1 or x > objects_layer.width or y < 1 or y > objects_layer.height then
        return nil
    end
    return objects_layer.data[y][x]
end

---@return number The tile ID of the player tile
function dungeon.find_player_tile_id()
    local found_tile_id = nil
    for gid, tile in pairs(dungeon.map.tiles) do
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
function dungeon.find_tile_by_id(tile_id)
    assert(dungeon.map ~= nil,
        "Map not loaded! This should never happen as we verify the map exists before calling this function.")

    local objects_layer = dungeon.get_objects_layer()
    for y = 1, objects_layer.height do
        for x = 1, objects_layer.width do
            local tile = dungeon.get_objects_tile(x, y)
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
---@field pos pos
---@field tile table
---@return PlayerSetup
function dungeon.get_player_start_position()
    local location = dungeon.find_tile_by_id(dungeon.find_player_tile_id())
    assert(location ~= nil, "Player tile not found in map! This should never happen as we verified the tile exists.")

    -- Add 0.5 to center the player in the tile
    return {
        pos = pos.new(location.x + 0.5, location.y + 0.5),
        tile = location.tile
    }
end

---Process all tiles and their properties, populating the various tile type tables
---@return nil
function dungeon.process_tiles()
    print("\nProcessing tiles:")
    for gid, tile in pairs(dungeon.map.tiles) do
        local props = tile.properties
        if not props then
            goto continue
        end

        -- Process by kind
        if props["kind"] then
            -- print(string.format("  Has kind: %s", props["kind"]))
            if props["kind"] == "enemy" then
                dungeon.enemies[gid] = table.clone(props)
                dungeon.enemies[gid].max_hitpoints = dungeon.enemies[gid].hitpoints
                dungeon.enemies[gid].tile = tile
            elseif props["kind"] == "weapon" then
                dungeon.weapons[gid] = table.clone(props)
                dungeon.weapons[gid].tile = tile
            elseif props["kind"] == "shield" then
                dungeon.shields[gid] = table.clone(props)
                dungeon.shields[gid].max_hitpoints = dungeon.shields[gid].hitpoints
                dungeon.shields[gid].tile = tile
            elseif props["kind"] == "chest" then
                -- Store chest animation frames in order
                local anim_frame = props["anim"] or 0
                dungeon.chest_anim[anim_frame + 1] = gid
            elseif props["kind"] == "player" then
                dungeon.player = table.clone(props)
                dungeon.player.max_hitpoints = dungeon.player.hitpoints
                dungeon.player.tile = tile
            end
        end

        ::continue::
    end
end

---Load and initialize the map, processing all tiles and their properties
---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function dungeon.load(opts)
    opts = opts or { reset = true }

    if opts.reset then
        -- Reset all state
        dungeon.map = STI("assets/maps/level1.lua")
        print("Map loaded:", dungeon.map.width, "x", dungeon.map.height)

        -- Reset all entity tables
        dungeon.enemies = {}
        dungeon.weapons = {}
        dungeon.shields = {}
        dungeon.chest_anim = {}
        dungeon.objects_layer = nil
        dungeon.player = nil

        -- Verify square tiles and set tile size
        assert(dungeon.map.tilewidth == dungeon.map.tileheight, 
            string.format("Tiles must be square! Width: %d, Height: %d", 
                dungeon.map.tilewidth, dungeon.map.tileheight))
        dungeon.tile_size = dungeon.map.tilewidth
        dungeon.map_size = pos.new(
            dungeon.map.width * dungeon.tile_size,
            dungeon.map.height * dungeon.tile_size
        )

        -- Process all tiles and their properties
        dungeon.process_tiles()

        -- Hide the Objects layer
        dungeon.map.layers[OBJECTS_LAYER_ID].visible = false
    end
end

---Create a new layer for overlapping tiles
---@param overlapping_tiles table[] Array of {x: number, y: number, tile: table} entries
function dungeon.make_overlap_layer(overlapping_tiles)
    -- Create a new layer with the same dimensions as the map
    local overlap_layer = {
        name = 3,
        type = "tilelayer",
        width = dungeon.map.width,
        height = dungeon.map.height,
        data = {},
        visible = true,
        opacity = 1,
        properties = {},
        x = 0,
        y = 0,
        offsetx = 0,
        offsety = 0,
        encoding = "lua",
        compression = nil
    }

    -- Initialize the data array with empty tiles (GID 0)
    for i = 1, dungeon.map.width * dungeon.map.height do
        overlap_layer.data[i] = 0
    end

    -- Place overlapping tiles in the new layer
    for _, tile_data in ipairs(overlapping_tiles) do
        local index = (tile_data.y - 1) * dungeon.map.width + tile_data.x
        overlap_layer.data[index] = tile_data.tile.gid
    end

    -- Initialize the layer using STI's setLayer function
    dungeon.map:setLayer(overlap_layer)
    dungeon.overlap_layer = overlap_layer

    -- Force STI to create sprite batches for this layer
    dungeon.map:setSpriteBatches(overlap_layer)
end

---Draw the base map layer
---@param translation_x number Camera translation X
---@param translation_y number Camera translation Y
function dungeon.draw_map(translation_x, translation_y)
    -- Show only base layer
    dungeon.map.layers[BASE_LAYER_ID].visible = true
    dungeon.map.layers[OBJECTS_LAYER_ID].visible = false
    dungeon.map.layers[OVERLAP_LAYER_ID].visible = false

    -- Draw the map
    dungeon.map:draw(translation_x, translation_y)
end

---Draw the overlap layer
---@param translation_x number Camera translation X
---@param translation_y number Camera translation Y
function dungeon.draw_overlaps(translation_x, translation_y)
    -- Show only overlap layer
    dungeon.map.layers[BASE_LAYER_ID].visible = false
    dungeon.map.layers[OBJECTS_LAYER_ID].visible = false
    dungeon.map.layers[OVERLAP_LAYER_ID].visible = true

    -- Draw the map
    dungeon.map:draw(translation_x, translation_y)
end

---Convert tile grid coordinates (1-based) to screen coordinates (0-based)
---@param grid_pos pos Grid position (1-based)
---@return pos screen_pos Screen coordinates (0-based)
function dungeon.grid_to_screen(grid_pos)
    return pos.new(
        math.round((grid_pos.x - 1) * dungeon.tile_size),
        math.round((grid_pos.y - 1) * dungeon.tile_size)
    )
end

return dungeon 