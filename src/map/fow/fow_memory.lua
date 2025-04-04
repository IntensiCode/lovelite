-- FOW Memory Module
-- Manages the memory grid that tracks previously seen tiles in the fog of war system.
-- Provides functionality to initialize, update, and query the memory grid.
-- Ensures that previously explored areas remain partially visible in field of view mode.
-- Handles restoring remembered visibility when toggling between FOW modes.

local fow_config = require("src.map.fow.fow_config")

local fow_memory = {}

---Initialize or update the memory grid to track maximum revealed visibility
---@param fog_of_war table The main fog of war module
function fow_memory.ensure_grid(fog_of_war)
    -- Initialize memory grid if it doesn't exist
    if not fow_config.memory_grid then
        fow_config.memory_grid = {}
        for y = 1, fow_config.size.y do
            fow_config.memory_grid[y] = {}
            for x = 1, fow_config.size.x do
                fow_config.memory_grid[y][x] = 0
            end
        end
    end
end

---Update the memory grid with new visibility values
---@param fog_of_war table The main fog of war module
---@param x number The x coordinate
---@param y number The y coordinate
---@param visibility number The new visibility level
function fow_memory.update(fog_of_war, x, y, visibility)
    if not fow_config.memory_grid then
        fow_memory.ensure_grid(fog_of_war)
    end
    
    -- Update memory with maximum visibility ever achieved
    fow_config.memory_grid[y][x] = math.max(fow_config.memory_grid[y][x], visibility)
end

---Apply memory to the current grid for areas outside field of view
---@param fog_of_war table The main fog of war module
function fow_memory.apply_to_grid(fog_of_war)
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            if fow_config.memory_grid[y][x] > 0 and fow_config.grid[y][x] == 0 then
                -- Previously seen but currently not visible tiles get visibility level 1
                fow_config.grid[y][x] = 1
            end
        end
    end
end

---Restore all memory to the visibility grid
---@param fog_of_war table The main fog of war module
function fow_memory.restore_to_grid(fog_of_war)
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            if fow_config.memory_grid[y][x] > 0 then
                fow_config.grid[y][x] = fow_config.memory_grid[y][x]
            end
        end
    end
end

return fow_memory 