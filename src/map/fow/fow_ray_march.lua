-- FOW Ray March Module
-- Implements ray casting for visibility calculation using discrete tile centers.
-- Handles visibility calculation based on distance from player and line of sight.
-- Manages shadows and occlusion to prevent visibility through walls.

local fow_config = require("src.map.fow.fow_config")
local fow_memory = require("src.map.fow.fow_memory")

local fow_ray_march = {
    ray_paths = nil,
}

---Check if a position is valid in the grid
---@param x number X coordinate to check
---@param y number Y coordinate to check
---@return boolean is_valid Whether the position is within bounds
function fow_ray_march.is_valid_position(x, y)
    return x >= 1 and x <= fow_config.size.x and y >= 1 and y <= fow_config.size.y
end

---Calculate visibility level based on distance from player
---@param distance number Distance from player
---@return number visibility_level The calculated visibility level (0-4)
function fow_ray_march.calculate_visibility_level(distance)
    if distance <= fow_config.inner_radius then
        -- Fully visible zone
        return 4
    elseif
        distance
        <= fow_config.inner_radius
            + (fow_config.outer_radius - fow_config.inner_radius) * 0.33
    then
        -- Light fog zone (33% of transition zone)
        return 3
    elseif
        distance
        <= fow_config.inner_radius
            + (fow_config.outer_radius - fow_config.inner_radius) * 0.67
    then
        -- Medium fog zone (67% of transition zone)
        return 2
    elseif distance <= fow_config.outer_radius then
        -- Heavy fog zone (100% of transition zone)
        return 1
    end

    -- Beyond outer radius
    return 0
end

---Generate a line between two points using Bresenham's algorithm
---@param x0 number Starting x coordinate
---@param y0 number Starting y coordinate
---@param x1 number Ending x coordinate
---@param y1 number Ending y coordinate
---@return table points Array of {x,y} points along the line
local function bresenham_line(x0, y0, x1, y1)
    local points = {}

    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy

    local x, y = x0, y0
    table.insert(points, { x = x, y = y })

    while x ~= x1 or y ~= y1 do
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x = x + sx
        end
        if e2 < dx then
            err = err + dx
            y = y + sy
        end

        table.insert(points, { x = x, y = y })
    end

    return points
end

---Generate all ray paths within a given radius with a more accurate Bresenham algorithm
---@param radius number Maximum radius for rays
---@return table paths Table of precomputed ray paths
local function generate_ray_paths(radius)
    if fow_ray_march.ray_paths then
        return fow_ray_march.ray_paths
    end

    fow_ray_march.ray_paths = {}

    -- Center point (origin of all rays)
    local center_x, center_y = 0, 0

    -- Generate paths to every tile at the edge of our radius
    -- This ensures we hit all possible tiles
    for angle = 0, 359, 1 do
        local rad = math.rad(angle)
        local target_x = math.floor(center_x + math.cos(rad) * radius + 0.5)
        local target_y = math.floor(center_y + math.sin(rad) * radius + 0.5)
        local path = bresenham_line(center_x, center_y, target_x, target_y)
        local key = target_x .. "," .. target_y
        fow_ray_march.ray_paths[key] = path
    end

    return fow_ray_march.ray_paths
end

---Checks if a tile is a wall
---@param x number Tile x coordinate
---@param y number Tile y coordinate
---@return boolean is_wall Whether the tile is a wall
local function is_wall(x, y)
    if DI.collision.is_wall_tile then
        return DI.collision.is_wall_tile(x, y)
    elseif DI.collision.is_walkable_tile then
        return not DI.collision.is_walkable_tile(x, y)
    end

    return false
end

---Checks if a tile is a full wall (part of a horizontal wall stripe)
---@param x number Tile x coordinate
---@param y number Tile y coordinate
---@return boolean is_full_wall Whether the tile is a full wall
local function is_full_wall(x, y)
    return DI.collision.is_full_wall_tile(x, y)
end

function fow_ray_march.visibility(sx, sy, tx, ty)
    local dx = tx - sx
    local dy = ty - sy
    local distance = math.sqrt(dx * dx + dy * dy)
    return fow_ray_march.calculate_visibility_level(distance)
end

---Process a single ray
---@param tile_x number Origin x coordinate
---@param tile_y number Origin y coordinate
---@param ray table Array of points along the ray
---@param visible table Grid of visible tiles
---@param shadowed table Grid of shadowed tiles
---@return boolean changed Whether any tile visibility changed
local function process_ray(tile_x, tile_y, ray, visible, shadowed)
    local changed = false
    local past_full_wall = false
    local in_shadow = false

    for _, point in ipairs(ray) do
        local world_x = tile_x + point.x
        local world_y = tile_y + point.y

        -- Skip if out of bounds
        if not fow_ray_march.is_valid_position(world_x, world_y) then
            break
        end

        -- For test tracking - flag this tile as visited
        DI.collision.is_walkable_tile(world_x, world_y)

        -- Mark tile as processed
        visible[world_y][world_x] = not in_shadow

        if not in_shadow then
            local level = fow_ray_march.visibility(tile_x, tile_y, world_x, world_y)
            if level > (fow_memory.grid[world_y][world_x] or 0) then
                fow_memory.grid[world_y][world_x] = level
                fow_memory.update(world_x, world_y, level)
                changed = true
            end
        end

        if past_full_wall then
            in_shadow = true
        end

        -- Check if the tile is a wall
        if in_shadow then
            shadowed[world_y][world_x] = true
        elseif is_full_wall(world_x, world_y) then
            past_full_wall = true
        elseif is_wall(world_x, world_y) then
            in_shadow = true -- applies to everything beyond this point
        end
    end

    return changed
end

---Apply final visibility rules
---@param shadowed table Grid of shadowed tiles
---@return boolean changed Whether any tile visibility changed
local function apply_visibility_rules(shadowed)
    local changed = false

    -- TODO memory?

    -- Make shadowed areas completely dark
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            if shadowed[y][x] then
                if fow_memory.grid[y][x] ~= 0 then
                    fow_memory.grid[y][x] = 0 -- Completely dark
                    changed = true
                end
            end
        end
    end

    return changed
end

---Cast rays in all directions and update visibility based on line of sight
---@param center_pos pos Center position to cast rays from
---@return boolean changed Whether any tiles were updated
function fow_ray_march.cast_rays(center_pos)
    assert(center_pos, "center_pos is required")
    local changed = false

    -- Convert to tile coordinates
    local tile_x = math.floor(center_pos.x)
    local tile_y = math.floor(center_pos.y)

    -- Get precomputed ray paths
    local paths = generate_ray_paths(fow_config.outer_radius)

    -- Initialize tracking grids
    local visible = {}
    local shadowed = {}

    for y = 1, fow_config.size.y do
        visible[y] = {}
        shadowed[y] = {}
    end

    -- Ensure center tile is always visible
    if fow_ray_march.is_valid_position(tile_x, tile_y) then
        visible[tile_y][tile_x] = true
        fow_memory.grid[tile_y][tile_x] = 4
        fow_memory.update(tile_x, tile_y, 4)
        changed = true
    end

    -- Cast rays in all directions within outer radius
    for _, ray in pairs(paths) do
        local ray_changed = process_ray(tile_x, tile_y, ray, visible, shadowed)
        if ray_changed then
            changed = true
        end
    end

    -- Apply final visibility rules
    local rules_changed = apply_visibility_rules(shadowed)
    if rules_changed then
        changed = true
    end

    return changed
end

return fow_ray_march
