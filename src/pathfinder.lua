local Grid = require("src/libraries/jumper/jumper.grid")
local Pathfinder = require("src/libraries/jumper/jumper.pathfinder")
local map_manager = require("src.map_manager")

---@class Pathfinder
---@field grid table The jumper grid instance
---@field pathfinder table The jumper pathfinder instance
---@field dijkstra_distances table<number, number> Map of node indices to their distances from start
---@field dijkstra_start_x number The x coordinate of the Dijkstra start point
---@field dijkstra_start_y number The y coordinate of the Dijkstra start point
local pathfinder = {
    grid = nil,
    pathfinder = nil,
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
            map[y][x] = is_walkable_fn(x, y) and 0 or 1
        end
    end
    
    -- Initialize pathfinding grid with the map
    pathfinder.grid = Grid(map)
    
    -- Create pathfinder instance
    pathfinder.pathfinder = Pathfinder(pathfinder.grid, "JPS", 0) -- 0 means no diagonal movement
end

---Find a path between two points on the map
---@param start_x number Starting X coordinate
---@param start_y number Starting Y coordinate
---@param end_x number Target X coordinate
---@param end_y number Target Y coordinate
---@return table|nil path The path as a list of {x, y} coordinates, or nil if no path found
function pathfinder.find_path(start_x, start_y, end_x, end_y)
    if not pathfinder.pathfinder then return nil end
    
    local path = pathfinder.pathfinder:findPath(start_x, start_y, end_x, end_y)
    if not path then return nil end
    
    -- Convert path to list of coordinates
    local result = {}
    for node, _ in path:iter() do
        table.insert(result, {x = node.x, y = node.y})
    end
    
    return result
end

---Calculate distances from a starting point to all reachable tiles using Dijkstra's algorithm
---@param start_x number Starting X coordinate
---@param start_y number Starting Y coordinate
---@param width number Grid width
---@param height number Grid height
---@return table<number, number>|nil distances Map of node indices to their distances from start, or nil if calculation failed
function pathfinder.calculate_dijkstra_distances(start_x, start_y, width, height)
    if not pathfinder.pathfinder then return nil end
    
    -- Create a new Dijkstra pathfinder
    local dijkstra = Pathfinder(pathfinder.grid, "DIJKSTRA", 0)
    
    -- Calculate distances to all reachable nodes
    local distances = {}
    local node_count = width * height
    
    -- Calculate distances
    for i = 1, node_count do
        local path = dijkstra:findPath(start_x, start_y, 
            ((i - 1) % width) + 1,
            math.floor((i - 1) / width) + 1)
        
        if path then
            -- Count nodes in path to get distance
            local distance = 0
            for _ in path:iter() do
                distance = distance + 1
            end
            distances[i] = distance
        end
    end
    
    -- Store the start point for future path finding
    pathfinder.dijkstra_start_x = start_x
    pathfinder.dijkstra_start_y = start_y
    pathfinder.dijkstra_distances = distances
    
    return distances
end

---Find a path from a given point back to the Dijkstra start point
---@param end_x number Ending X coordinate
---@param end_y number Ending Y coordinate
---@return table|nil path The path as a list of {x, y} coordinates, or nil if no path found
function pathfinder.find_path_to_start(end_x, end_y)
    if not pathfinder.dijkstra_distances or 
       not pathfinder.dijkstra_start_x or 
       not pathfinder.dijkstra_start_y then
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
    if not pathfinder.dijkstra_distances then return nil end
    
    -- Convert coordinates to node index
    local node_index = (y - 1) * width + x
    return pathfinder.dijkstra_distances[node_index]
end

return pathfinder 