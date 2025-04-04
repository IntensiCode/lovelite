require("src.base.pos")
require("src.base.table")

local lu = require("src.libraries.luaunit")

local fow_config = require("src.map.fow.fow_config")
local fow_fov = require("src.map.fow.fow_fov")

test_fow_fov = {}

function test_fow_fov:setup()
    -- Initialize basic fog of war configuration
    fow_config.size = { x = 10, y = 10 }
    fow_config.grid = {}
    fow_config.memory_grid = {}
    fow_config.enabled = true
    fow_config.inner_radius = 3
    fow_config.outer_radius = 6
    fow_config.field_of_view_mode = true
    fow_config.canvas_dirty = true
    fow_config.prev_player_pos = nil

    -- Initialize grid and memory grid
    for y = 1, fow_config.size.y do
        fow_config.grid[y] = {}
        fow_config.memory_grid[y] = {}
        for x = 1, fow_config.size.x do
            fow_config.grid[y][x] = 0
            fow_config.memory_grid[y][x] = 0
        end
    end

    -- Store original collision functions
    self.original_is_walkable_tile = DI.collision.is_walkable_tile
    self.original_is_full_wall_tile = DI.collision.is_full_wall_tile
    self.original_is_wall_tile = DI.collision.is_wall_tile

    -- Setup mock collision system for testing
    DI.collision.is_walkable_tile = function(x, y)
        return true
    end
    DI.collision.is_full_wall_tile = function(x, y)
        return false
    end
    DI.collision.is_wall_tile = function(x, y)
        return false
    end
end

function test_fow_fov:teardown()
    -- Reset fog of war configuration
    fow_config.grid = nil
    fow_config.memory_grid = nil
    fow_config.size = nil
    fow_config.enabled = nil
    fow_config.inner_radius = nil
    fow_config.outer_radius = nil
    fow_config.field_of_view_mode = nil
    fow_config.canvas_dirty = nil
    fow_config.prev_player_pos = nil

    -- Restore original collision functions
    if self.original_is_walkable_tile then
        DI.collision.is_walkable_tile = self.original_is_walkable_tile
    end
    if self.original_is_full_wall_tile then
        DI.collision.is_full_wall_tile = self.original_is_full_wall_tile
    end
    if self.original_is_wall_tile then
        DI.collision.is_wall_tile = self.original_is_wall_tile
    end
end

function test_fow_fov:test_update_resets_visibility()
    -- Set initial visibility
    fow_config.grid[1][1] = 4

    -- Update from center position
    fow_fov.update({}, { x = 5, y = 5 })

    -- Distant tile should be dark
    lu.assertEquals(fow_config.grid[1][1], 1) -- Memory level visibility
end

function test_fow_fov:test_update_ray_casting()
    -- Update from center position
    fow_fov.update({}, { x = 5, y = 5 })

    -- Check visibility at different distances
    lu.assertEquals(fow_config.grid[5][5], 4) -- Center
    lu.assertEquals(fow_config.grid[5][6], 4) -- One tile away
    lu.assertEquals(fow_config.grid[1][1], 1) -- Memory level visibility
end

function test_fow_fov:test_update_updates_memory_grid()
    -- Update from center position
    fow_fov.update({}, { x = 5, y = 5 })

    -- Check memory grid values
    lu.assertEquals(fow_config.memory_grid[5][5], 4) -- Center
    lu.assertEquals(fow_config.memory_grid[1][1], 1) -- Memory level visibility
end

function test_fow_fov:test_update_applies_memory_for_previously_seen()
    -- Set up some memory
    fow_config.memory_grid = {}
    for y = 1, fow_config.size.y do
        fow_config.memory_grid[y] = {}
        for x = 1, fow_config.size.x do
            fow_config.memory_grid[y][x] = 0
        end
    end
    fow_config.memory_grid[1][1] = 3

    -- Update FOV from position (5,5)
    fow_fov.update({}, { x = 5, y = 5 })

    -- Verify previously seen tile has minimum visibility
    lu.assertEquals(fow_config.grid[1][1], 1)
end

function test_fow_fov:test_set_mode_enabled_does_nothing()
    -- Set initial state
    fow_config.field_of_view_mode = true

    -- Try to enable when already enabled
    local changed = fow_fov.set_mode({}, true)

    -- Verify no change
    lu.assertFalse(changed)
    lu.assertTrue(fow_config.field_of_view_mode)
end

function test_fow_fov:test_set_mode_disabled_restores_memory()
    -- Set up some memory
    fow_config.memory_grid = {}
    for y = 1, fow_config.size.y do
        fow_config.memory_grid[y] = {}
        for x = 1, fow_config.size.x do
            fow_config.memory_grid[y][x] = 0
        end
    end
    fow_config.memory_grid[1][1] = 3

    -- Enable FOV mode first
    fow_config.field_of_view_mode = true

    -- Disable FOV mode
    local changed = fow_fov.set_mode({}, false)

    -- Verify memory was restored
    lu.assertTrue(changed)
    lu.assertEquals(fow_config.grid[1][1], 3)
    lu.assertFalse(fow_config.field_of_view_mode)
end

function test_fow_fov:test_set_mode_enabled_saves_memory()
    -- Set up some visibility and ensure FOV mode is off initially
    fow_config.field_of_view_mode = false
    fow_config.grid[1][1] = 3
    fow_config.memory_grid[1][1] = 0

    -- Enable FOV mode
    local changed = fow_fov.set_mode({}, true)

    -- Verify state was saved to memory and mode was changed
    lu.assertTrue(changed)
    lu.assertEquals(fow_config.memory_grid[1][1], 3)
    lu.assertTrue(fow_config.field_of_view_mode)
end

function test_fow_fov:test_field_of_view_darkens_areas_outside_view()
    -- Set initial visibility
    fow_config.grid[1][1] = 4

    -- Update from center position
    fow_fov.update({}, { x = 5, y = 5 })

    -- Areas outside view should be dark or memory level
    lu.assertEquals(fow_config.grid[1][1], 1) -- Memory level visibility
end

function test_fow_fov:test_field_of_view_minimum_visibility_level()
    -- Set up some memory
    fow_config.memory_grid = {}
    for y = 1, fow_config.size.y do
        fow_config.memory_grid[y] = {}
        for x = 1, fow_config.size.x do
            fow_config.memory_grid[y][x] = 0
        end
    end
    fow_config.memory_grid[1][1] = 4

    -- Update FOV from distant position
    fow_fov.update({}, { x = 5, y = 5 })

    -- Verify remembered area has minimum visibility
    lu.assertEquals(fow_config.grid[1][1], 1)
end

return test_fow_fov
