local pos = require("src.base.pos")

local pathfinding = {}

---Check if player's tile position has changed and update pathfinding if needed
---@param player table The player object
---@param current_tile pos The current tile position
function pathfinding.check_tile_position_change(player, current_tile)
    -- Initialize last_tile if not set
    player.last_tile = player.last_tile or pos.new(-1, -1)

    -- Check if tile position changed
    if current_tile.x ~= player.last_tile.x or current_tile.y ~= player.last_tile.y then
        -- Update pathfinding data
        pathfinding.update_pathfinder(player, current_tile)
        -- Store new position
        player.last_tile = current_tile
    end
end

---Update pathfinding data for the current tile position
---@param player table The player object
---@param current_tile pos The current tile position
function pathfinding.update_pathfinder(player, current_tile)
    if not current_tile then return end

    -- Get map dimensions from dungeon
    local map_width = DI.dungeon.map.width
    local map_height = DI.dungeon.map.height

    -- Calculate Dijkstra distances from current tile position
    DI.pathfinder.calculate_dijkstra_distances(
        current_tile.x,
        current_tile.y,
        map_width,
        map_height
    )
end

return pathfinding 