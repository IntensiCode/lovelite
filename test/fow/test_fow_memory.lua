require("src.base.pos")
require("src.base.table")

local lu = require("src.libraries.luaunit")

local fow_config = require("src.map.fow.fow_config")
local fow_memory = require("src.map.fow.fow_memory")

test_fow_memory = {}

function test_fow_memory:setup()
    -- Initialize basic fog of war configuration
    fow_config.size = { x = 10, y = 10 }
    fow_config.grid = {}
    fow_config.memory_grid = nil

    -- Initialize grid
    for y = 1, fow_config.size.y do
        fow_config.grid[y] = {}
        for x = 1, fow_config.size.x do
            fow_config.grid[y][x] = 0
        end
    end
end

function test_fow_memory:teardown()
    fow_config.grid = nil
    fow_config.memory_grid = nil
    fow_config.size = nil
end

function test_fow_memory:test_ensure_grid_initialization()
    -- Test initial state
    lu.assertNil(fow_config.memory_grid)

    -- Initialize memory grid
    fow_memory.ensure_grid({})

    -- Verify grid was created
    lu.assertNotNil(fow_config.memory_grid)
    lu.assertEquals(#fow_config.memory_grid, fow_config.size.y)
    lu.assertEquals(#fow_config.memory_grid[1], fow_config.size.x)

    -- Verify all cells are initialized to 0
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            lu.assertEquals(fow_config.memory_grid[y][x], 0)
        end
    end
end

function test_fow_memory:test_ensure_grid_does_not_reinitialize()
    -- First initialization
    fow_memory.ensure_grid({})

    -- Modify a value
    fow_config.memory_grid[1][1] = 4

    -- Call ensure_grid again
    fow_memory.ensure_grid({})

    -- Verify value was preserved
    lu.assertEquals(fow_config.memory_grid[1][1], 4)
end

function test_fow_memory:test_update()
    -- Initialize grid
    fow_memory.ensure_grid({})

    -- Update a position
    fow_memory.update({}, 1, 1, 3)

    -- Verify update
    lu.assertEquals(fow_config.memory_grid[1][1], 3)

    -- Update with lower value
    fow_memory.update({}, 1, 1, 2)

    -- Verify maximum is kept
    lu.assertEquals(fow_config.memory_grid[1][1], 3)

    -- Update with higher value
    fow_memory.update({}, 1, 1, 4)

    -- Verify new maximum
    lu.assertEquals(fow_config.memory_grid[1][1], 4)
end

function test_fow_memory:test_apply_to_grid()
    -- Initialize grid
    fow_memory.ensure_grid({})

    -- Set some memory values
    fow_memory.update({}, 1, 1, 3)
    fow_memory.update({}, 2, 2, 2)

    -- Apply memory to grid
    fow_memory.apply_to_grid({})

    -- Verify remembered areas get minimum visibility
    lu.assertEquals(fow_config.grid[1][1], 1)
    lu.assertEquals(fow_config.grid[2][2], 1)

    -- Verify unremembered areas stay dark
    lu.assertEquals(fow_config.grid[3][3], 0)
end

function test_fow_memory:test_restore_to_grid()
    -- Initialize grid
    fow_memory.ensure_grid({})

    -- Set some memory values
    fow_memory.update({}, 1, 1, 3)
    fow_memory.update({}, 2, 2, 2)

    -- Restore memory to grid
    fow_memory.restore_to_grid({})

    -- Verify full memory values are restored
    lu.assertEquals(fow_config.grid[1][1], 3)
    lu.assertEquals(fow_config.grid[2][2], 2)

    -- Verify unremembered areas stay dark
    lu.assertEquals(fow_config.grid[3][3], 0)
end

function test_fow_memory:test_memory_records_max_visibility()
    -- Initialize grid
    fow_memory.ensure_grid({})

    -- Update with increasing values
    fow_memory.update({}, 1, 1, 2)
    fow_memory.update({}, 1, 1, 3)
    fow_memory.update({}, 1, 1, 4)

    -- Verify maximum is recorded
    lu.assertEquals(fow_config.memory_grid[1][1], 4)

    -- Update with decreasing values
    fow_memory.update({}, 1, 1, 3)
    fow_memory.update({}, 1, 1, 2)
    fow_memory.update({}, 1, 1, 1)

    -- Verify maximum is preserved
    lu.assertEquals(fow_config.memory_grid[1][1], 4)
end

return test_fow_memory
