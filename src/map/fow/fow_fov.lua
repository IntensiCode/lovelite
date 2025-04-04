-- FOW Field of View Module
-- Implements "true" field of view functionality where only currently visible areas are shown.
-- Resets visibility each update and applies ray casting for up-to-date line of sight.
-- Manages the memory grid to remember previously seen areas.
-- Handles toggling between field of view mode and traditional fog of war.

local fow_config = require("src.map.fow.fow_config")
local fow_memory = require("src.map.fow.fow_memory")
local fow_ray_march = require("src.map.fow.fow_ray_march")

local fow_fov = {}

-- Minimum visibility level for memory grid in field of view mode
local MEMORY_VISIBILITY_LEVEL = 1

---Apply field of view based visibility from a center position
---@param center_pos pos Center position for field of view
---@return boolean changed Whether any tiles were updated
function fow_fov.update(center_pos)
    assert(center_pos, "center_pos is required")
    local changed = false

    -- First, save the memory grid state to apply later
    local memory_values = {}
    for y = 1, fow_config.size.y do
        memory_values[y] = {}
        for x = 1, fow_config.size.x do
            memory_values[y][x] = fow_memory.memory_grid[y][x]
        end
    end

    -- Reset all tiles to fully hidden (0)
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            if fow_memory.grid[y][x] ~= 0 then
                fow_memory.grid[y][x] = 0
                changed = true
            end
        end
    end

    -- Use ray casting to determine line of sight
    local los_changed = fow_ray_march.cast_rays(center_pos)
    if los_changed then
        changed = true

        -- Update memory grid for all currently visible tiles
        for y = 1, fow_config.size.y do
            for x = 1, fow_config.size.x do
                if fow_memory.grid[y][x] > 0 then
                    -- Update memory grid with current visibility
                    fow_memory.update(x, y, fow_memory.grid[y][x])
                end
            end
        end
    end

    -- Apply memory for previously seen tiles (with minimum visibility level)
    fow_memory.for_each_position(function(x, y, v, m)
        if v == 0 and m > 0 then
            fow_memory.grid[y][x] = MEMORY_VISIBILITY_LEVEL
            changed = true
        end
    end)

    return changed
end

---Toggle between field of view mode and traditional fog of war
---@param enabled boolean Whether field of view mode should be enabled
---@return boolean changed Whether any tiles were updated
function fow_fov.set_mode(enabled)
    -- If no change in mode, do nothing
    if fow_config.field_of_view_mode == enabled then
        return false
    end

    -- Set the new mode
    fow_config.field_of_view_mode = enabled

    local changed = false

    -- If disabling field of view mode, restore remembered visibility
    if not enabled then
        fow_memory.restore_to_grid()
        changed = true
    else
        -- If enabling field of view mode, save the current grid to memory first
        -- Then update to show only what's currently visible
        fow_memory.for_each_position(function(x, y, v, m)
            if v > m then
                fow_memory.memory_grid[y][x] = v
            end
        end)
        changed = true
    end

    return changed
end

return fow_fov
