-- FOW Reveal Module
-- Handles revealing and updating tile visibility in the fog of war system.
-- Provides functions to reveal areas around a position and manage field of view mode.
-- Coordinates with ray marching and memory modules to determine final visibility.

local fow_config = require("src.map.fow.fow_config")
local fow_fov = require("src.map.fow.fow_fov")
local fow_memory = require("src.map.fow.fow_memory")
local fow_ray_march = require("src.map.fow.fow_ray_march")
local pos = require("src.base.pos")

local fow_reveal = {}

---Check if a tile position is valid in the grid
---@param x number Tile X coordinate
---@param y number Tile Y coordinate
---@return boolean is_valid Whether the position is within the grid
function fow_reveal.is_valid_position(x, y)
    return fow_memory.is_valid_position(x, y)
end

---Reveal the area around a position
---@param center_pos table The position to reveal around
---@return boolean changed Whether any tiles were updated
function fow_reveal.reveal_around(center_pos)
    -- Don't do anything if FOW is disabled
    if not fow_config.enabled then
        return false
    end

    -- Check if the position has changed
    if
        fow_config.prev_player_pos
        and center_pos.x == fow_config.prev_player_pos.x
        and center_pos.y == fow_config.prev_player_pos.y
    then
        return false -- No change in position
    end

    -- Save current position
    fow_config.prev_player_pos = pos.new(center_pos.x, center_pos.y)

    -- In field of view mode, delegate to FOV-specific update
    if fow_config.field_of_view_mode then
        return fow_fov.update(center_pos)
    end

    return fow_ray_march.cast_rays(center_pos)
end

---Reveal the entire map
---@return boolean changed Whether any tiles were newly revealed
function fow_reveal.reveal_all()
    local changed = false
    fow_memory.for_each_position(function(x, y, v, m)
        if v < 4 then
            fow_memory.grid[y][x] = 4
            fow_memory.memory_grid[y][x] = 4
            changed = true
        end
    end)
    return changed
end

---Toggle field of view mode on/off
---@param enabled boolean Whether field of view mode should be enabled
---@return boolean changed Whether any visibility values were changed
function fow_reveal.set_field_of_view_mode(enabled)
    -- Delegate to FOV-specific mode setting
    local changed = fow_fov.set_mode(enabled)
    if changed and not enabled then
        fow_memory.restore_to_grid()
    end
    return changed
end

return fow_reveal
