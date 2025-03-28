local pos = require("src.base.pos")
local movement = require("src.enemy.behaviors.movement")

---@class Enemy
---@field pos pos
---@field backoff_tile pos|nil
---@field backoff number|nil
---@field speed number
local backoff = {}

---Find the best backoff tile (furthest from player)
---@param enemy Enemy The enemy to find a backoff tile for
---@return pos|nil The best backoff tile position, or nil if no walkable tiles found
function backoff.find_best_tile(enemy)
    local player_pos = DI.player.pos
    local current_tile_x = math.floor(enemy.pos.x + 0.5)
    local current_tile_y = math.floor(enemy.pos.y + 0.5)

    local walkable_tiles = DI.collision.find_walkable_around(current_tile_x, current_tile_y)
    if #walkable_tiles == 0 then return nil end

    -- Create table of tiles with their distances
    local tiles_with_distances = {}
    for _, tile in ipairs(walkable_tiles) do
        local tile_pos = pos.new(tile.x + 0.5, tile.y + 0.5)
        local distance = (tile_pos - player_pos):length()
        
        -- Only consider tiles that are further from the player than our current position
        -- and not the tile we're currently on
        local current_distance = (enemy.pos - player_pos):length()
        local is_different_tile = math.abs(tile_pos.x - enemy.pos.x) > 0.1 or math.abs(tile_pos.y - enemy.pos.y) > 0.1
        
        if is_different_tile and distance > current_distance then
            table.insert(tiles_with_distances, {pos = tile_pos, distance = distance})
        end
    end

    -- If no valid tiles found, try again without the distance requirement
    if #tiles_with_distances == 0 then
        for _, tile in ipairs(walkable_tiles) do
            local tile_pos = pos.new(tile.x + 0.5, tile.y + 0.5)
            -- At least make sure it's a different tile
            if math.abs(tile_pos.x - enemy.pos.x) > 0.1 or math.abs(tile_pos.y - enemy.pos.y) > 0.1 then
                local distance = (tile_pos - player_pos):length()
                table.insert(tiles_with_distances, {pos = tile_pos, distance = distance})
            end
        end
    end

    -- If still no valid tiles, return nil
    if #tiles_with_distances == 0 then
        return nil
    end

    -- Sort by distance
    table.sort(tiles_with_distances, function(a, b)
        return a.distance < b.distance
    end)

    -- Find all tiles that have the same (closest) distance
    local closest_tiles = {}
    local closest_distance = tiles_with_distances[1].distance
    for _, tile in ipairs(tiles_with_distances) do
        if math.abs(tile.distance - closest_distance) < 0.01 then
            table.insert(closest_tiles, tile.pos)
        else
            break  -- Stop once we find a different distance
        end
    end

    -- Pick a random tile from the closest ones
    return closest_tiles[math.random(#closest_tiles)]
end

---Check if the enemy needs a new backoff target (no target or reached current one)
---@param enemy Enemy The enemy to check
---@return boolean Whether the enemy needs a new backoff target
function backoff.needs_new_target(enemy)
    if not enemy.backoff_tile then return true end
    return math.abs(enemy.pos.x - enemy.backoff_tile.x) < 0.1 and
        math.abs(enemy.pos.y - enemy.backoff_tile.y) < 0.1
end

---Check if the enemy is still in backoff state
---@param enemy Enemy The enemy to check
---@return boolean Whether the enemy is still backing off
function backoff.is_still_backing_off(enemy)
    return enemy.backoff ~= nil and enemy.backoff > 0
end

---Update backoff movement
---@param enemy Enemy The enemy to update
---@param dt number Delta time in seconds
function backoff.update(enemy, dt)
    enemy.backoff = enemy.backoff - dt

    -- If we need a new backoff target
    if backoff.needs_new_target(enemy) then
        -- Find a new backoff tile
        enemy.backoff_tile = backoff.find_best_tile(enemy)
    end

    -- Move towards the backoff tile if we have one
    if enemy.backoff_tile then
        movement.move_towards_target(enemy, enemy.backoff_tile, dt)
    end

    -- If backoff is done, clear the backoff tile
    if enemy.backoff <= 0 then
        enemy.backoff = nil
        enemy.backoff_tile = nil
    end
end

return backoff
