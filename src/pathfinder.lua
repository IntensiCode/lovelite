local map_manager = require("src.map_manager")
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
function pathfinder.load()
    -- Initialize pathfinder with map dimensions and walkable function
    pathfinder.init(
        map_manager.map.width,
        map_manager.map.height,
        map_manager.is_walkable_tile
    )
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

---Find a path from a given point back to the Dijkstra start point
---@param end_x number Ending X coordinate
---@param end_y number Ending Y coordinate
---@return table|nil path The path as a list of {x, y} coordinates, or nil if no path found
function pathfinder.find_path_to_start(end_x, end_y)
    assert(pathfinder.dijkstra_distances, "Dijkstra distances not calculated")

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

    local tile_size = map_manager.map.tilewidth
    local max_dist = 0

    -- Find maximum distance for color scaling
    for _, dist in pairs(pathfinder.dijkstra_distances) do
        if dist ~= math.huge and dist > max_dist then
            max_dist = dist
        end
    end

    local debug_size = 0.25

    -- Draw distance visualization
    for y = 1, #pathfinder.grid do
        for x = 1, #pathfinder.grid[y] do
            local index = (y - 1) * #pathfinder.grid[y] + x
            local dist = pathfinder.dijkstra_distances[index]

            if dist ~= math.huge then
                -- Calculate color based on distance using interpolate_color
                local t = dist / max_dist
                local color = constants.interpolate_color(t, constants.pathfinder_colors)

                -- Draw rectangle in center of tile
                love.graphics.setColor(unpack(color))
                love.graphics.rectangle("fill",
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

return pathfinder
