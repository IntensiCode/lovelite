local dungeon = require("src.map.dungeon")
local constants = require("src.base.constants")

---@class Pathfinder
---@field grid table The jumper grid instance
---@field dijkstra_distances table<number, number> Map of node indices to their distances from start
---@field dijkstra_start_x number The x coordinate of the Dijkstra start point
---@field dijkstra_start_y number The y coordinate of the Dijkstra start point
local pathfinder = {
    grid = nil,
    dijkstra_distances = nil,
    dijkstra_start_x = nil,
    dijkstra_start_y = nil
}

---Load and initialize the pathfinder using the current map
---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function pathfinder.load(opts)
    opts = opts or { reset = true }

    if opts.reset then
        -- Reset all pathfinding state
        pathfinder.grid = nil
        pathfinder.dijkstra_distances = nil
        pathfinder.dijkstra_start_x = nil
        pathfinder.dijkstra_start_y = nil

        -- Initialize pathfinder with map dimensions and walkable function
        pathfinder.init(
            DI.dungeon.map.width,
            DI.dungeon.map.height,
            DI.collision.is_walkable_tile
        )
    end
end

---Initialize the pathfinder with a grid
---@param width number Grid width
---@param height number Grid height
---@param is_walkable_fn function Function that takes (x,y) and returns whether that tile is walkable
function pathfinder.init(width, height, is_walkable_fn)
    -- Create a 2D array representing the map
    local map = {}
    for y = 1, height do
        map[y] = {}
        for x = 1, width do
            -- 0 for walkable, 1 for non-walkable
            map[y][x] = {}
            map[y][x].walkable = is_walkable_fn(x, y) and 0 or 1
            map[y][x].cost = nil
        end
    end

    -- Initialize pathfinding grid with the map
    pathfinder.grid = map
end

---Calculate distances from a starting point to all reachable tiles using Dijkstra's algorithm
---@param start_x number Starting X coordinate
---@param start_y number Starting Y coordinate
---@param width number Grid width
---@param height number Grid height
function pathfinder.calculate_dijkstra_distances(start_x, start_y, width, height)
    -- Initialize distances and visited arrays
    local distances = {}
    local visited = {}
    local node_count = width * height

    -- Initialize all distances to infinity and visited to false
    for i = 1, node_count do
        distances[i] = math.huge
        visited[i] = false
    end

    -- Set start node distance to 0
    local start_index = (start_y - 1) * width + start_x
    distances[start_index] = 0

    -- Main Dijkstra loop
    while true do
        -- Find unvisited node with smallest distance
        local min_dist = math.huge
        local current = nil

        for i = 1, node_count do
            if not visited[i] and distances[i] < min_dist then
                min_dist = distances[i]
                current = i
            end
        end

        -- If no unvisited nodes or all remaining nodes are unreachable
        if not current or min_dist == math.huge then
            break
        end

        -- Mark current node as visited
        visited[current] = true

        -- Get current node coordinates
        local current_x = ((current - 1) % width) + 1
        local current_y = math.floor((current - 1) / width) + 1

        -- Check all four directions (up, right, down, left)
        local directions = {
            { dx = 0,  dy = -1 }, -- up
            { dx = 1,  dy = 0 }, -- right
            { dx = 0,  dy = 1 }, -- down
            { dx = -1, dy = 0 } -- left
        }

        for _, dir in ipairs(directions) do
            local new_x = current_x + dir.dx
            local new_y = current_y + dir.dy

            -- Check if neighbor is within bounds
            if new_x >= 1 and new_x <= width and new_y >= 1 and new_y <= height then
                -- Check if neighbor is walkable
                if pathfinder.grid[new_y][new_x].walkable == 0 then
                    local neighbor_index = (new_y - 1) * width + new_x

                    -- If neighbor is unvisited and new path is shorter
                    if not visited[neighbor_index] then
                        local new_dist = distances[current] + 1
                        if new_dist < distances[neighbor_index] then
                            distances[neighbor_index] = new_dist
                        end
                    end
                end
            end
        end
    end

    -- Store the start point for future path finding
    pathfinder.dijkstra_start_x = start_x
    pathfinder.dijkstra_start_y = start_y
    pathfinder.dijkstra_distances = distances
end

---Find a path between two points using the pre-calculated Dijkstra distances
---@param start_x number Starting X coordinate
---@param start_y number Starting Y coordinate
---@param end_x number Ending X coordinate
---@param end_y number Ending Y coordinate
---@return table|nil path The path as a list of {x, y} coordinates, or nil if no path found
function pathfinder.find_path(start_x, start_y, end_x, end_y)
    assert(pathfinder.dijkstra_distances, "Dijkstra distances not calculated")

    local width = #pathfinder.grid[1]
    local path = {}
    local current_x, current_y = start_x, start_y

    -- Check if start point is reachable
    local start_index = (start_y - 1) * width + start_x
    if pathfinder.dijkstra_distances[start_index] == math.huge then
        return nil
    end

    -- Add start point to path
    table.insert(path, { x = current_x, y = current_y })

    -- Follow decreasing distances until we reach the end
    while current_x ~= end_x or current_y ~= end_y do
        local current_index = (current_y - 1) * width + current_x
        local current_dist = pathfinder.dijkstra_distances[current_index]
        local best_dist = current_dist
        local best_x, best_y = nil, nil

        -- Check all four directions
        local directions = {
            { dx = 0,  dy = -1 }, -- up
            { dx = 1,  dy = 0 },  -- right
            { dx = 0,  dy = 1 },  -- down
            { dx = -1, dy = 0 }   -- left
        }

        for _, dir in ipairs(directions) do
            local next_x = current_x + dir.dx
            local next_y = current_y + dir.dy

            -- Check if neighbor is within bounds and walkable
            if next_x >= 1 and next_x <= width and next_y >= 1 and next_y <= #pathfinder.grid then
                if pathfinder.grid[next_y][next_x].walkable == 0 then
                    local next_index = (next_y - 1) * width + next_x
                    local next_dist = pathfinder.dijkstra_distances[next_index]

                    -- If this neighbor is closer to the end point, remember it
                    if next_dist < best_dist then
                        best_dist = next_dist
                        best_x, best_y = next_x, next_y
                    end
                end
            end
        end

        -- If we couldn't find a better neighbor, we're stuck
        if not best_x then
            return nil
        end

        -- Move to the best neighbor
        current_x, current_y = best_x, best_y
        table.insert(path, { x = current_x, y = current_y })
    end

    return path
end

---Find a path from a given point back to the Dijkstra start point
---@param end_x number Ending X coordinate
---@param end_y number Ending Y coordinate
---@return table|nil path The path as a list of {x, y} coordinates, or nil if no path found
function pathfinder.find_path_to_start(end_x, end_y)
    if not pathfinder.dijkstra_distances then
        return nil
    end

    -- Use the stored Dijkstra distances to find path back to start
    return pathfinder.find_path(end_x, end_y,
        pathfinder.dijkstra_start_x,
        pathfinder.dijkstra_start_y)
end

---Get the distance from a point to the Dijkstra start point
---@param x number X coordinate
---@param y number Y coordinate
---@param width number Grid width
---@return number|nil distance The distance to the start point, or nil if not reachable
function pathfinder.get_distance_to_start(x, y, width)
    assert(pathfinder.dijkstra_distances, "Dijkstra distances not calculated")

    -- Convert coordinates to node index
    local node_index = (y - 1) * width + x
    return pathfinder.dijkstra_distances[node_index]
end

---Draw the Dijkstra distances for debugging
function pathfinder.draw()
    if not pathfinder.dijkstra_distances then return end

    local tile_size = dungeon.tile_size
    local max_dist = 0

    -- Find maximum distance for color scaling
    for _, dist in pairs(pathfinder.dijkstra_distances) do
        if dist ~= math.huge and dist > max_dist then
            max_dist = dist
        end
    end

    local debug_size = 0.5

    -- Draw distance visualization
    for y = 1, #pathfinder.grid do
        for x = 1, #pathfinder.grid[y] do
            local index = (y - 1) * #pathfinder.grid[y] + x
            local dist = pathfinder.dijkstra_distances[index]

            if dist ~= math.huge then
                -- Calculate color based on distance using interpolate_color
                local t = dist / max_dist
                local color = constants.interpolate_color(t, constants.pathfinder_colors)
                -- Set alpha to 0.25
                color[4] = 0.5
                -- Draw rectangle in center of tile
                love.graphics.setColor(unpack(color))
                love.graphics.rectangle("line",
                    (x - 1) * tile_size + tile_size * (1 - debug_size) / 2,
                    (y - 1) * tile_size + tile_size * (1 - debug_size) / 2,
                    tile_size * debug_size,
                    tile_size * debug_size
                )
            end
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

---Clear all pathfinding data
function pathfinder.clear()
    pathfinder.dijkstra_distances = nil
    pathfinder.dijkstra_start_x = nil
    pathfinder.dijkstra_start_y = nil
end

return pathfinder
