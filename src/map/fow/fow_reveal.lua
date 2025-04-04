-- FOW Reveal Module
-- Main entry point for fog of war functionality that coordinates between components.
-- Handles revealing tiles around positions, revealing the entire map,
-- and toggling between field of view and traditional fog of war modes.
-- Delegates to specialized modules for memory, ray marching, and field of view.

local pos = require("src.base.pos")
local fow_ray_march = require("src.map.fow.fow_ray_march")
local fow_memory = require("src.map.fow.fow_memory")
local fow_fov = require("src.map.fow.fow_fov")
local fow_config = require("src.map.fow.fow_config")

local fow_reveal = {}

---Check if a tile position is valid in the grid
---@param fog_of_war table The main fog of war module
---@param x number Tile X coordinate
---@param y number Tile Y coordinate
---@return boolean is_valid Whether the position is within the grid
function fow_reveal.is_valid_position(fog_of_war, x, y)
    return fow_ray_march.is_valid_position(fog_of_war, x, y)
end

-- Helper function to calculate distance between two points
local function calculate_distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Helper function to calculate visibility based on distance for traditional mode
local function calculate_visibility_for_traditional_mode(fog_of_war, distance)
    if distance <= fow_config.inner_radius then
        return 4  -- Fully visible
    elseif distance <= fow_config.inner_radius + (fow_config.outer_radius - fow_config.inner_radius) * 0.33 then
        return 3  -- Light fog
    elseif distance <= fow_config.inner_radius + (fow_config.outer_radius - fow_config.inner_radius) * 0.67 then
        return 2  -- Medium fog
    elseif distance <= fow_config.outer_radius then
        return 1  -- Heavy fog
    else
        return 0  -- Not visible
    end
end

-- Process visibility in traditional mode
local function process_traditional_mode(fog_of_war, center_pos)
    local changed = false
    
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            -- Calculate distance and visibility level
            local distance = calculate_distance(center_pos.x, center_pos.y, x, y)
            local visibility = calculate_visibility_for_traditional_mode(fog_of_war, distance)
            
            -- Update visibility if higher
            if fow_config.grid[y][x] < visibility then
                fow_config.grid[y][x] = visibility
                fow_memory.update(fog_of_war, x, y, visibility)
                changed = true
            end
            
            ::continue::
        end
    end
    
    return changed
end

---Reveal the area around a position
---@param fog_of_war table The fog of war module
---@param center_pos table The position to reveal around
---@return boolean changed Whether any tiles were updated
function fow_reveal.reveal_around(fog_of_war, center_pos)
    -- Don't do anything if FOW is disabled
    if not fow_config.enabled then
        return false
    end
    
    -- Check if the position has changed
    if fow_config.prev_player_pos and 
       center_pos.x == fow_config.prev_player_pos.x and
       center_pos.y == fow_config.prev_player_pos.y then
        return false -- No change in position
    end
    
    -- Save current position
    if not fow_config.prev_player_pos then
        fow_config.prev_player_pos = {x = center_pos.x, y = center_pos.y}
    else
        fow_config.prev_player_pos.x = center_pos.x
        fow_config.prev_player_pos.y = center_pos.y
    end
    
    -- In field of view mode, delegate to FOV-specific update
    if fow_config.field_of_view_mode then
        return fow_fov.update(fog_of_war, center_pos)
    end
    
    return fow_ray_march.cast_rays(fog_of_war, center_pos)
end

---Reveal the entire map
---@param fog_of_war table The main fog of war module
---@return boolean changed Whether any tiles were newly revealed
function fow_reveal.reveal_all(fog_of_war)
    -- Ensure memory grid exists
    fow_memory.ensure_grid(fog_of_war)
    
    local changed = false
    
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            if fow_config.grid[y][x] ~= 4 then  -- Check if already fully visible
                fow_config.grid[y][x] = 4  -- Fully visible
                fow_config.memory_grid[y][x] = 4  -- Remember it was fully visible
                changed = true
            end
        end
    end
    
    return changed
end

---Set field of view mode
---@param fog_of_war table The fog of war module
---@param enabled boolean Whether to enable field of view mode
---@return boolean changed Whether the mode was changed
function fow_reveal.set_field_of_view_mode(fog_of_war, enabled)
    -- Delegate to FOV-specific mode setting
    local changed = fow_fov.set_mode(fog_of_war, enabled)
    fow_config.field_of_view_mode = enabled
    return changed
end

return fow_reveal 