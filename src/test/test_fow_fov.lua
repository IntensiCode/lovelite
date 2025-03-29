require("src.base.table")

local lu = require("src.libraries.luaunit")
local pos = require("src.base.pos")

TestFowFov = {}

function TestFowFov:setUp()
    -- Reload the module to ensure clean state for each test
    package.loaded["src.map.fow_fov"] = nil
    package.loaded["src.map.fow_ray_march"] = nil
    package.loaded["src.map.fow_memory"] = nil
    
    self.fow_fov = require("src.map.fow_fov")
    self.fow_ray_march = require("src.map.fow_ray_march")
    self.fow_memory = require("src.map.fow_memory")
    
    -- Create a mock fog_of_war object with minimal requirements
    self.fog_of_war = {
        grid = {},
        size = pos.new(10, 10),  -- 10x10 grid for testing
        inner_radius = 3,
        outer_radius = 6,
        field_of_view_mode = false,
        enabled = true,
        memory_grid = {},
        _is_test = true  -- Flag to identify test context
    }
    
    -- Initialize grid to all unexplored (0)
    for y = 1, self.fog_of_war.size.y do
        self.fog_of_war.grid[y] = {}
        self.fog_of_war.memory_grid[y] = {}
        for x = 1, self.fog_of_war.size.x do
            self.fog_of_war.grid[y][x] = 0
            self.fog_of_war.memory_grid[y][x] = 0
        end
    end
    
    -- Setup mock collision system for testing
    self.original_is_walkable_tile = nil
    if DI and DI.collision then
        self.original_is_walkable_tile = DI.collision.is_walkable_tile
    end
    
    -- Default mock makes all tiles walkable
    DI = DI or {}
    DI.collision = DI.collision or {}
    DI.collision.is_walkable_tile = function(x, y) return true end
end

function TestFowFov:tearDown()
    -- Clean up mocks
    if self.original_is_walkable_tile then
        DI.collision.is_walkable_tile = self.original_is_walkable_tile
    end
end

function TestFowFov:testUpdateResetsVisibility()
    -- Arrange
    -- Set some tiles to visible
    for y = 1, self.fog_of_war.size.y do
        for x = 1, self.fog_of_war.size.x do
            self.fog_of_war.grid[y][x] = 4  -- Set all tiles to fully visible
        end
    end
    
    -- Act
    self.fow_fov.update(self.fog_of_war, pos.new(5, 5))
    
    -- Assert
    -- Check tiles outside FOV are reset
    lu.assertEquals(self.fog_of_war.grid[1][1], 0, 
                   "Distant tiles should be reset to 0 visibility")
    
    -- But the center should be visible
    lu.assertEquals(self.fog_of_war.grid[5][5], 4, 
                   "Center position should be visible")
end

function TestFowFov:testUpdateRayCasting()
    -- Arrange
    local center = pos.new(5, 5)
    
    -- Act
    self.fow_fov.update(self.fog_of_war, center)
    
    -- Assert
    -- Check visibility at different distances
    -- Center tile should be fully visible
    lu.assertEquals(self.fog_of_war.grid[5][5], 4, 
                   "Center tile should be fully visible")
    
    -- A tile within inner radius should be fully visible
    lu.assertEquals(self.fog_of_war.grid[3][5], 4, 
                   "Tile within inner radius should be fully visible")
    
    -- A tile at transition zone should have partial visibility
    -- Actual value depends on distance and visibility calculation
    lu.assertNotEquals(self.fog_of_war.grid[9][5], 0, 
                      "Tile within outer radius should have some visibility")
                      
    -- A distant tile should be hidden
    lu.assertEquals(self.fog_of_war.grid[1][1], 0, 
                   "Distant tile should remain hidden")
end

function TestFowFov:testUpdateUpdatesMemoryGrid()
    -- Arrange
    local center = pos.new(5, 5)
    
    -- Act
    self.fow_fov.update(self.fog_of_war, center)
    
    -- Assert
    -- Memory grid should record visibility for visible tiles
    lu.assertEquals(self.fog_of_war.memory_grid[5][5], 4, 
                   "Memory grid should record full visibility for center")
    
    -- Check memory for a medium-distance tile
    lu.assertNotEquals(self.fog_of_war.memory_grid[8][5], 0, 
                      "Memory grid should record visibility for medium distance tiles")
end

function TestFowFov:testUpdateAppliesMemoryForPreviouslySeen()
    -- Arrange
    -- First reveal from center1
    local center1 = pos.new(3, 3)
    self.fow_fov.update(self.fog_of_war, center1)
    
    -- Now move to center2 which is distant from center1
    local center2 = pos.new(8, 8)
    
    -- Act
    self.fow_fov.update(self.fog_of_war, center2)
    
    -- Assert
    -- Center1 should no longer be fully visible, but should have minimal visibility from memory
    lu.assertNotEquals(self.fog_of_war.grid[center1.y][center1.x], 4, 
                      "Old center should no longer be fully visible")
    lu.assertNotEquals(self.fog_of_war.grid[center1.y][center1.x], 0, 
                      "Old center should have minimal visibility from memory")
    
    -- Center2 should now be fully visible
    lu.assertEquals(self.fog_of_war.grid[center2.y][center2.x], 4, 
                   "New center should be fully visible")
end

function TestFowFov:testSetModeEnabledDoesNothing()
    -- Arrange
    self.fog_of_war.field_of_view_mode = true
    
    -- Act
    local changed = self.fow_fov.set_mode(self.fog_of_war, true)
    
    -- Assert
    lu.assertFalse(changed, "set_mode should return false when already in the requested mode")
end

function TestFowFov:testSetModeDisabledRestoresMemory()
    -- Arrange
    self.fog_of_war.field_of_view_mode = true
    
    -- Set up memory grid with known values
    self.fog_of_war.memory_grid[3][3] = 4
    self.fog_of_war.memory_grid[5][5] = 2
    
    -- Set up grid with different values
    self.fog_of_war.grid[3][3] = 1
    self.fog_of_war.grid[5][5] = 0
    
    -- Act
    local changed = self.fow_fov.set_mode(self.fog_of_war, false)
    
    -- Assert
    lu.assertTrue(changed, "set_mode should return true when mode changes")
    lu.assertFalse(self.fog_of_war.field_of_view_mode, "field_of_view_mode should be updated")
    
    -- Memory values should be restored to grid
    lu.assertEquals(self.fog_of_war.grid[3][3], 4, 
                   "Fully visible memory should be restored to grid")
    lu.assertEquals(self.fog_of_war.grid[5][5], 2, 
                   "Partially visible memory should be restored to grid")
end

function TestFowFov:testSetModeEnabledSavesMemory()
    -- Arrange
    self.fog_of_war.field_of_view_mode = false
    
    -- Set up grid with known values
    self.fog_of_war.grid[3][3] = 4
    self.fog_of_war.grid[5][5] = 2
    
    -- Act
    local changed = self.fow_fov.set_mode(self.fog_of_war, true)
    
    -- Assert
    lu.assertTrue(changed, "set_mode should return true when mode changes")
    lu.assertTrue(self.fog_of_war.field_of_view_mode, "field_of_view_mode should be updated")
    
    -- Memory should be updated with max values
    lu.assertEquals(self.fog_of_war.memory_grid[3][3], 4, 
                   "Memory should record current visibility when enabling FOV")
    lu.assertEquals(self.fog_of_war.memory_grid[5][5], 2, 
                   "Memory should record current visibility when enabling FOV")
end

function TestFowFov:testFieldOfViewDarkensAreasOutsideView()
    -- Arrange
    local center1 = pos.new(3, 3)
    local center2 = pos.new(8, 8)
    
    -- First reveal center1
    self.fow_fov.update(self.fog_of_war, center1)
    
    -- Act
    -- Move to center2, which should leave center1 outside current field of view
    self.fow_fov.update(self.fog_of_war, center2)
    
    -- Assert
    lu.assertNotEquals(self.fog_of_war.grid[center1.y][center1.x], 4, 
                      "Point outside field of view should be darkened")
end

function TestFowFov:testFieldOfViewMinimumVisibilityLevel()
    -- Arrange
    local center1 = pos.new(3, 3)
    local center2 = pos.new(8, 8)
    
    -- First reveal at center1
    self.fow_fov.update(self.fog_of_war, center1)
    
    -- Act
    -- Move to center2, which should leave center1 outside current field of view
    self.fow_fov.update(self.fog_of_war, center2)
    
    -- Assert
    -- Verify center1 is at the minimum visibility level 1
    lu.assertEquals(self.fog_of_war.grid[center1.y][center1.x], 1, 
                   "Previously seen areas should have minimum visibility level 1")
end

return TestFowFov 