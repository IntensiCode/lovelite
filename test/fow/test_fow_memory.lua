require("src.base.pos")
require("src.base.table")

local lu = require("src.libraries.luaunit")

local fow_config = require("src.map.fow.fow_config")
local fow_memory = require("src.map.fow.fow_memory")

test_fow_memory = {}

function test_fow_memory:setup()
    -- Initialize basic fog of war configuration
    fow_config.size = { x = 10, y = 10 }
    -- Initialize memory grids with default visibility 0
    fow_memory.init(0)
end

function test_fow_memory:teardown()
    fow_config.size = nil
    -- No need to explicitly clear grids as they're internal to fow_memory
end

function test_fow_memory:test_init()
    -- Test initial state
    lu.assertNotNil(fow_memory.grid)
    lu.assertNotNil(fow_memory.memory_grid)
    
    -- Verify grid dimensions
    lu.assertEquals(#fow_memory.grid, fow_config.size.y)
    lu.assertEquals(#fow_memory.grid[1], fow_config.size.x)

    -- Verify all cells are initialized to 0
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            lu.assertEquals(fow_memory.get_visibility(x, y), 0)
            lu.assertEquals(fow_memory.get_memory(x, y), 0)
        end
    end
end

function test_fow_memory:test_memory_persistence()
    -- Set a value
    fow_memory.set_memory(1, 1, 4)

    -- Re-init with different value
    fow_memory.init(0)

    -- Verify grid was reset
    lu.assertEquals(fow_memory.get_memory(1, 1), 0)
end

function test_fow_memory:test_update()
    -- Update a position
    fow_memory.update(1, 1, 3)

    -- Verify update
    lu.assertEquals(fow_memory.get_memory(1, 1), 3)

    -- Update with lower value
    fow_memory.update(1, 1, 2)

    -- Verify maximum is kept
    lu.assertEquals(fow_memory.get_memory(1, 1), 3)

    -- Update with higher value
    fow_memory.update(1, 1, 4)

    -- Verify new maximum
    lu.assertEquals(fow_memory.get_memory(1, 1), 4)
end

function test_fow_memory:test_apply_to_grid()
    -- Set some memory values
    fow_memory.update(1, 1, 3)
    fow_memory.update(2, 2, 2)

    -- Reset visibility
    fow_memory.reset_visibility(0)

    -- Apply memory to grid
    fow_memory.apply_to_grid()

    -- Verify remembered areas get minimum visibility
    lu.assertEquals(fow_memory.get_visibility(1, 1), 1)
    lu.assertEquals(fow_memory.get_visibility(2, 2), 1)

    -- Verify unremembered areas stay dark
    lu.assertEquals(fow_memory.get_visibility(3, 3), 0)
end

function test_fow_memory:test_restore_to_grid()
    -- Set some memory values
    fow_memory.update(1, 1, 3)
    fow_memory.update(2, 2, 2)

    -- Reset visibility
    fow_memory.reset_visibility(0)

    -- Restore memory to grid
    fow_memory.restore_to_grid()

    -- Verify full memory values are restored
    lu.assertEquals(fow_memory.get_visibility(1, 1), 3)
    lu.assertEquals(fow_memory.get_visibility(2, 2), 2)

    -- Verify unremembered areas stay dark
    lu.assertEquals(fow_memory.get_visibility(3, 3), 0)
end

function test_fow_memory:test_memory_records_max_visibility()
    -- Update with increasing values
    fow_memory.update(1, 1, 2)
    fow_memory.update(1, 1, 3)
    fow_memory.update(1, 1, 4)

    -- Verify maximum is recorded
    lu.assertEquals(fow_memory.get_memory(1, 1), 4)

    -- Update with decreasing values
    fow_memory.update(1, 1, 3)
    fow_memory.update(1, 1, 2)
    fow_memory.update(1, 1, 1)

    -- Verify maximum is preserved
    lu.assertEquals(fow_memory.get_memory(1, 1), 4)
end

return test_fow_memory
