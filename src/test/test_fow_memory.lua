require("src.base.table")

local lu = require("src.libraries.luaunit")
local pos = require("src.base.pos")

TestFowMemory = {}

function TestFowMemory:setUp()
    -- Reload the modules to ensure clean state for each test
    package.loaded["src.map.fow_memory"] = nil
    self.fow_memory = require("src.map.fow_memory")
    
    -- Create a mock fog_of_war object with minimal requirements
    self.fog_of_war = {
        grid = {},
        size = pos.new(10, 10),  -- 10x10 grid for testing
        inner_radius = 3,
        outer_radius = 6,
        enabled = true
    }
    
    -- Initialize grid to all unexplored (0)
    for y = 1, self.fog_of_war.size.y do
        self.fog_of_war.grid[y] = {}
        for x = 1, self.fog_of_war.size.x do
            self.fog_of_war.grid[y][x] = 0
        end
    end
end

function TestFowMemory:testEnsureGridInitialization()
    -- Arrange
    -- Act
    self.fow_memory.ensure_grid(self.fog_of_war)
    
    -- Assert
    lu.assertNotNil(self.fog_of_war.memory_grid, "Memory grid should be created")
    
    -- Check that memory grid has correct dimensions and default values
    lu.assertEquals(#self.fog_of_war.memory_grid, self.fog_of_war.size.y, "Memory grid should have correct height")
    lu.assertEquals(#self.fog_of_war.memory_grid[1], self.fog_of_war.size.x, "Memory grid should have correct width")
    
    -- Verify values are initialized to 0
    for y = 1, self.fog_of_war.size.y do
        for x = 1, self.fog_of_war.size.x do
            lu.assertEquals(self.fog_of_war.memory_grid[y][x], 0, 
                           string.format("Memory grid at (%d,%d) should be initialized to 0", x, y))
        end
    end
end

function TestFowMemory:testEnsureGridDoesNotReinitialize()
    -- Arrange
    self.fow_memory.ensure_grid(self.fog_of_war)
    
    -- Set a specific memory value
    self.fog_of_war.memory_grid[5][5] = 4
    
    -- Act
    self.fow_memory.ensure_grid(self.fog_of_war)
    
    -- Assert
    lu.assertEquals(self.fog_of_war.memory_grid[5][5], 4, 
                   "Memory grid should preserve existing values when ensure_grid is called again")
end

function TestFowMemory:testUpdate()
    -- Arrange
    self.fow_memory.ensure_grid(self.fog_of_war)
    local x, y = 3, 3
    
    -- Act
    self.fow_memory.update(self.fog_of_war, x, y, 2)
    
    -- Assert
    lu.assertEquals(self.fog_of_war.memory_grid[y][x], 2, 
                   "Memory grid should update to the new visibility value")
    
    -- Act again with lower value
    self.fow_memory.update(self.fog_of_war, x, y, 1)
    
    -- Assert
    lu.assertEquals(self.fog_of_war.memory_grid[y][x], 2, 
                   "Memory grid should keep the maximum visibility ever achieved")
    
    -- Act again with higher value
    self.fow_memory.update(self.fog_of_war, x, y, 4)
    
    -- Assert
    lu.assertEquals(self.fog_of_war.memory_grid[y][x], 4, 
                   "Memory grid should update to higher visibility values")
end

function TestFowMemory:testApplyToGrid()
    -- Arrange
    self.fow_memory.ensure_grid(self.fog_of_war)
    
    -- Set up memory values
    self.fog_of_war.memory_grid[3][3] = 4  -- Fully visible before
    self.fog_of_war.memory_grid[5][5] = 2  -- Medium fog before
    
    -- All grid values start at 0 (unexplored)
    
    -- Act
    self.fow_memory.apply_to_grid(self.fog_of_war)
    
    -- Assert
    lu.assertEquals(self.fog_of_war.grid[3][3], 1, 
                   "Tiles with memory but not currently visible should get minimal visibility")
    lu.assertEquals(self.fog_of_war.grid[5][5], 1, 
                   "All previously seen tiles should have same minimal visibility regardless of previous level")
    
    -- Test that tiles without memory remain unexplored
    lu.assertEquals(self.fog_of_war.grid[7][7], 0, 
                   "Tiles without memory should remain unexplored")
    
    -- Test that setting grid value before applying memory keeps current value
    self.fog_of_war.grid[3][3] = 0  -- Reset to unexplored
    self.fog_of_war.grid[9][9] = 4  -- Set to fully visible
    self.fow_memory.apply_to_grid(self.fog_of_war)
    
    lu.assertEquals(self.fog_of_war.grid[3][3], 1, 
                   "Memory should still apply to tiles reset to unexplored")
    lu.assertEquals(self.fog_of_war.grid[9][9], 4, 
                   "Tiles already visible should remain at their current visibility")
end

function TestFowMemory:testRestoreToGrid()
    -- Arrange
    self.fow_memory.ensure_grid(self.fog_of_war)
    
    -- Set up memory values
    self.fog_of_war.memory_grid[3][3] = 4  -- Fully visible before
    self.fog_of_war.memory_grid[5][5] = 2  -- Medium fog before
    
    -- Act
    self.fow_memory.restore_to_grid(self.fog_of_war)
    
    -- Assert
    lu.assertEquals(self.fog_of_war.grid[3][3], 4, 
                   "Tiles with memory should be restored to their maximum visibility")
    lu.assertEquals(self.fog_of_war.grid[5][5], 2, 
                   "Tiles with partial visibility in memory should be restored to that level")
    
    -- Test that tiles without memory remain unexplored
    lu.assertEquals(self.fog_of_war.grid[7][7], 0, 
                   "Tiles without memory should remain unexplored")
    
    -- Test interaction with existing grid values
    self.fog_of_war.grid[3][3] = 1  -- Set to minimal visibility
    self.fog_of_war.grid[9][9] = 4  -- Set to fully visible
    self.fow_memory.restore_to_grid(self.fog_of_war)
    
    lu.assertEquals(self.fog_of_war.grid[3][3], 4, 
                   "Restore should overwrite current grid values with memory values")
    lu.assertEquals(self.fog_of_war.grid[9][9], 4, 
                   "Tiles without memory should keep current visibility")
end

function TestFowMemory:testMemoryRecordsMaxVisibility()
    -- Arrange
    self.fow_memory.ensure_grid(self.fog_of_war)
    local x, y = 3, 3
    
    -- Act - multiple updates with different visibility levels
    self.fow_memory.update(self.fog_of_war, x, y, 2)
    self.fow_memory.update(self.fog_of_war, x, y, 4)
    self.fow_memory.update(self.fog_of_war, x, y, 1)
    
    -- Assert
    lu.assertEquals(self.fog_of_war.memory_grid[y][x], 4, 
                   "Memory grid should record maximum visibility ever achieved")
end

return TestFowMemory 