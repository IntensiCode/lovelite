-- FOW Memory Module
-- Handles grid management and memory for fog of war system.
-- Provides functions to initialize, update, and access visibility grids.

local fow_config = require("src.map.fow.fow_config")

local fow_memory = {
    grid = nil,
    memory_grid = nil,
}

---Initialize grids with given dimensions and default value
---@param initial_value number Default visibility value
function fow_memory.init(initial_value)
    assert(type(initial_value) == "number", "Default value must be a number")
    assert(fow_config.size, "fow_config.size must be set before initializing grids")
    assert(fow_config.size.x > 0, "Grid dimensions must be positive")
    assert(fow_config.size.y > 0, "Grid dimensions must be positive")

    -- Initialize memory grid
    local height = fow_config.size.y
    local width = fow_config.size.x
    fow_memory.grid = {}
    fow_memory.memory_grid = {}
    for y = 1, height do
        fow_memory.grid[y] = {}
        fow_memory.memory_grid[y] = {}
        for x = 1, width do
            fow_memory.grid[y][x] = initial_value
            fow_memory.memory_grid[y][x] = initial_value
        end
    end
end

---Update the memory grid with new visibility values
---@param x number The x coordinate
---@param y number The y coordinate
---@param visibility number The new visibility level
function fow_memory.update(x, y, visibility)
    assert(fow_memory.is_valid_position(x, y), "Invalid position")
    assert(type(visibility) == "number", "Visibility must be a number")
    assert(fow_memory.memory_grid, "Memory grid not initialized")
    local current_memory = fow_memory.memory_grid[y][x]
    fow_memory.memory_grid[y][x] = math.max(current_memory, visibility)
end

---Apply memory to the current grid for areas outside field of view
function fow_memory.apply_to_grid()
    fow_memory.for_each_position(function(x, y, visibility, memory)
        if memory > 0 and visibility == 0 then
            -- Previously seen but currently not visible tiles get visibility level 1
            fow_memory.grid[y][x] = 1
        end
    end)
end

---Restore all memory to the visibility grid
function fow_memory.restore_to_grid()
    fow_memory.for_each_position(function(x, y, _, memory)
        if memory > 0 then
            fow_memory.grid[y][x] = memory
        end
    end)
end

---Reset visibility to a specific value while preserving memory
---@param value number The value to reset visibility to
function fow_memory.reset_visibility(value)
    fow_memory.for_each_position(function(x, y)
        fow_memory.grid[y][x] = value
    end)
end

---Check if position is within grid bounds
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean is_valid Whether the position is valid
function fow_memory.is_valid_position(x, y)
    assert(fow_config.size, "fow_config.size must be set")
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    return x >= 1 and x <= fow_config.size.x and y >= 1 and y <= fow_config.size.y
end

---Get visibility level at a position
---@param x number The x coordinate
---@param y number The y coordinate
---@return number visibility The visibility level at the position
function fow_memory.get_visibility(x, y)
    assert(fow_memory.is_valid_position(x, y), "Invalid position")
    assert(fow_memory.grid, "Grid not initialized")
    return fow_memory.grid[y][x]
end

---Get memory level at a position
---@param x number The x coordinate
---@param y number The y coordinate
---@return number memory The memory level at the position
function fow_memory.get_memory(x, y)
    assert(fow_memory.is_valid_position(x, y), "Invalid position")
    assert(fow_memory.memory_grid, "Memory grid not initialized")
    return fow_memory.memory_grid[y][x] or 0
end

---Set visibility level at a position
---@param x number The x coordinate
---@param y number The y coordinate
---@param visibility number The visibility level to set
function fow_memory.set_visibility(x, y, visibility)
    assert(type(visibility) == "number", "Visibility must be a number")
    assert(fow_memory.grid, "Grid not initialized")
    assert(fow_memory.is_valid_position(x, y), "Invalid position")
    fow_memory.grid[y][x] = visibility
end

---Set memory level at a position
---@param x number The x coordinate
---@param y number The y coordinate
---@param memory number The memory level to set
function fow_memory.set_memory(x, y, memory)
    assert(fow_memory.is_valid_position(x, y), "Invalid position")
    assert(type(memory) == "number", "Memory must be a number")
    assert(fow_memory.memory_grid, "Memory grid not initialized")
    fow_memory.memory_grid[y][x] = memory
end

---Iterate over all grid positions and call the callback for each
---@param callback fun(x: number, y: number, visibility: number, memory: number) The callback to call for each position
function fow_memory.for_each_position(callback)
    assert(fow_memory.grid and fow_memory.memory_grid, "Grids not initialized")
    assert(type(callback) == "function", "Callback must be a function")
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            callback(x, y, fow_memory.grid[y][x], fow_memory.memory_grid[y][x])
        end
    end
end

return fow_memory
