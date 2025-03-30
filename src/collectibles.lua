local pos = require("src.base.pos")

---@class Collectible
---@field pos pos
---@field tile table Reference to the tile from dungeon.tiles
---@field weapon table Reference to the weapon from dungeon.weapons (optional, only if this is a weapon collectible)
---@field hover_offset number
---@field hover_time number
local collectibles = {
    items = {},
    hover_offset = 2.5, -- How much to hover up/down
    hover_speed = 2.5,  -- Speed of hover animation
}

---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function collectibles.load(opts)
    opts = opts or { reset = true }

    if opts.reset then
        -- Clear existing items
        collectibles.items = {}

        -- Get the Objects layer
        local objects_layer = DI.dungeon.get_objects_layer()

        -- Process each tile in the Objects layer
        for y = 1, objects_layer.height do
            for x = 1, objects_layer.width do
                local tile = DI.dungeon.get_objects_tile(x, y)
                if tile and tile.properties then
                    if tile.properties["kind"] == "weapon" then
                        -- Get the weapon reference from dungeon
                        local weapon = DI.dungeon.weapons[tile.gid]
                        if weapon then
                            -- Create a collectible for this weapon tile
                            table.insert(collectibles.items, {
                                pos = pos.new(x, y),
                                tile = tile,     -- Store reference to the tile
                                name = weapon.name,
                                weapon = weapon, -- Store reference to the weapon
                                hover_offset = 0,
                                hover_time = math.random() * 2 * math.pi
                            })
                        end
                    elseif tile.properties["kind"] == "shield" then
                        -- Get the shield reference from dungeon
                        local shield = DI.dungeon.shields[tile.gid]
                        if shield then
                            -- Create a collectible for this shield tile
                            table.insert(collectibles.items, {
                                pos = pos.new(x, y),
                                name = shield.name,
                                tile = tile,     -- Store reference to the tile
                                shield = shield, -- Store reference to the shield
                                hover_offset = 0,
                                hover_time = math.random() * 2 * math.pi
                            })
                        end
                    end
                end
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
    -- Helper function to check if an item overlaps with player
    local function is_overlapping_player(pos)
        return math.abs(pos.x - DI.player.pos.x) < 1 and
            math.abs(pos.y - DI.player.pos.y) < 1
    end

    -- Store original graphics state
    local original_color = { love.graphics.getColor() }
    local original_blend_mode = love.graphics.getBlendMode()
    love.graphics.setBlendMode("alpha")

    for _, item in ipairs(collectibles.items) do
        -- Convert tile position to screen position
        local screen_pos = DI.dungeon.grid_to_screen(item.pos)

        -- Get tile dimensions
        local _, _, tile_width, tile_height = item.tile.quad:getViewport()

        -- Draw a dark gray circle below as pseudo-shadow
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.circle("fill", screen_pos.x + tile_width / 2, screen_pos.y + tile_height, 3)

        -- Set transparency if this specific item overlaps player
        if is_overlapping_player(item.pos) then
            love.graphics.setColor(1, 1, 1, 0.75)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        -- Draw collectible centered with hover offset
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            item.tile.quad,
            screen_pos.x,
            screen_pos.y + item.hover_offset,
            0,
            1, 1
        )
    end

    -- Restore original graphics state
    love.graphics.setColor(unpack(original_color))
    love.graphics.setBlendMode(original_blend_mode)
end

---Check if a position is close enough to collect a collectible
---@param pos pos The position to check
---@param collect_range number The range within which to collect (in tile units)
---@return table|nil The collected item if one was collected, nil otherwise
function collectibles.check_collection(pos, collect_range)
    collect_range = collect_range or 0.75 -- Default to half a tile

    local i = 1
    while i <= #collectibles.items do
        local item = collectibles.items[i]
        -- Use item.pos + 0.5 to account for the tile center
        local distance = (item.pos + pos.new(0.5, 0.5) - pos):length()

        if distance <= collect_range then
            -- Debug print collection
            log.info(string.format("Collectible collected at (%d, %d)! Weapon: %s",
                item.pos.x, item.pos.y, item.name))

            -- Play pickup sound
            DI.sound.play("pickup")

            -- Remove and return the collected item
            local collected = table.remove(collectibles.items, i)
            return collected
        end

        i = i + 1
    end

    return nil
end

return collectibles
