---@diagnostic disable: duplicate-set-field
require("src.base.log")
require("src.base.pos")
require("src.base.table")

local lu = require("src.libraries.luaunit")

local fow_config = require("src.map.fow.fow_config")
local fow_reveal = require("src.map.fow.fow_reveal")
local fow_draw = require("src.map.fow.fow_draw")
local fow_memory = require("src.map.fow.fow_memory")

-- Mock DI system for tests
DI = {
    collision = {}
}

test_fow_reveal = {}

-- Helper function to calculate distance between two points
local function calculate_distance(center_x, center_y, point_x, point_y)
    local dx = point_x - center_x
    local dy = point_y - center_y
    return math.sqrt(dx * dx + dy * dy)
end

function test_fow_reveal:setup()
    -- Initialize basic fog of war configuration
    fow_config.size = { x = 10, y = 10 }
    fow_config.enabled = true
    fow_config.inner_radius = 3
    fow_config.outer_radius = 6
    fow_config.field_of_view_mode = false
    fow_config.prev_player_pos = nil

    -- Initialize memory grids
    fow_memory.init(0)

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

function test_fow_reveal:teardown()
    -- Reset fog of war configuration
    fow_config.size = nil
    fow_config.enabled = nil
    fow_config.inner_radius = nil
    fow_config.outer_radius = nil
    fow_config.field_of_view_mode = nil
    fow_draw.canvas_dirty = nil
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

function test_fow_reveal:test_position_validation()
    -- Test valid positions
    lu.assertTrue(fow_reveal.is_valid_position(1, 1))
    lu.assertTrue(fow_reveal.is_valid_position(10, 10))

    -- Test invalid positions
    lu.assertFalse(fow_reveal.is_valid_position(0, 1))
    lu.assertFalse(fow_reveal.is_valid_position(1, 0))
    lu.assertFalse(fow_reveal.is_valid_position(11, 1))
    lu.assertFalse(fow_reveal.is_valid_position(1, 11))
end

function test_fow_reveal:test_is_valid_position_rejects_out_of_bounds()
    -- Test positions outside grid
    lu.assertFalse(fow_reveal.is_valid_position(0, 5))
    lu.assertFalse(fow_reveal.is_valid_position(5, 0))
    lu.assertFalse(fow_reveal.is_valid_position(11, 5))
    lu.assertFalse(fow_reveal.is_valid_position(5, 11))
end

function test_fow_reveal:test_reveal_around_center()
    -- Reveal around center position
    local changed = fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Verify changes were made
    lu.assertTrue(changed)
    lu.assertEquals(fow_memory.get_visibility(5, 5), 4) -- Center should be fully visible
    lu.assertEquals(fow_memory.get_visibility(5, 6), 4) -- Adjacent tile should be visible
    lu.assertEquals(fow_memory.get_visibility(1, 1), 1) -- Distant tile should have memory level visibility
end

function test_fow_reveal:test_reveal_around_inner_radius()
    -- Reveal around center position
    fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Check visibility within inner radius
    lu.assertEquals(fow_memory.get_visibility(5, 5), 4) -- Center
    lu.assertEquals(fow_memory.get_visibility(5, 6), 4) -- One tile away
    lu.assertEquals(fow_memory.get_visibility(5, 7), 4) -- Two tiles away
    lu.assertEquals(fow_memory.get_visibility(5, 8), 4) -- Three tiles away
end

function test_fow_reveal:test_reveal_around_transition_zone()
    -- Reveal around center position
    fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Check visibility in transition zone
    lu.assertEquals(fow_memory.get_visibility(5, 5), 4) -- Center tile should be fully visible
    lu.assertEquals(fow_memory.get_visibility(5, 8), 4) -- Edge of inner radius
    lu.assertEquals(fow_memory.get_visibility(5, 9), 2) -- Medium fog zone
    lu.assertEquals(fow_memory.get_visibility(5, 10), 2) -- Still medium fog zone
end

function test_fow_reveal:test_reveal_around_outside_radius()
    -- Reveal around center position
    fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Check visibility beyond outer radius (outer_radius is 6)
    -- Points at (1,1), (2,1), (3,1) are about 5.7 tiles away from (5,5)
    -- We need to check points that are > 6 tiles away
    lu.assertEquals(fow_memory.get_visibility(1, 10), 0) -- About 7.1 tiles away
    lu.assertEquals(fow_memory.get_visibility(10, 1), 0) -- About 7.1 tiles away
    lu.assertEquals(fow_memory.get_visibility(10, 10), 0) -- About 7.1 tiles away
end

function test_fow_reveal:test_reveal_around_never_decreases()
    -- Set initial visibility
    fow_memory.set_visibility(5, 5, 4)

    -- Reveal around different position
    fow_reveal.reveal_around({ x = 8, y = 8 })

    -- Verify visibility wasn't decreased
    lu.assertEquals(fow_memory.get_visibility(5, 5), 4)
end

function test_fow_reveal:test_reveal_around_returns_false_when_same_position()
    -- First reveal
    fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Second reveal at same position
    local changed = fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Verify no changes were made
    lu.assertFalse(changed)
end

function test_fow_reveal:test_reveal_all()
    -- Reveal entire map
    local changed = fow_reveal.reveal_all()

    -- Verify all tiles are fully visible
    lu.assertTrue(changed)
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            lu.assertEquals(fow_memory.get_visibility(x, y), 4)
        end
    end
end

function test_fow_reveal:test_reveal_all_returns_false_when_all_visible()
    -- First reveal
    fow_reveal.reveal_all()

    -- Second reveal
    local changed = fow_reveal.reveal_all()

    -- Verify no changes were made
    lu.assertFalse(changed)
end

function test_fow_reveal:test_reveal_around_does_nothing_when_disabled()
    -- Disable fog of war
    fow_config.enabled = false

    -- Try to reveal
    local changed = fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Verify no changes were made
    lu.assertFalse(changed)
    lu.assertEquals(fow_memory.get_visibility(5, 5), 0)
end

function test_fow_reveal:test_reveal_around_uses_fov_update()
    -- Enable field of view mode
    fow_config.field_of_view_mode = true

    -- Reveal around position
    local changed = fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Verify FOV update was used
    lu.assertTrue(changed)
    lu.assertEquals(fow_memory.get_visibility(5, 5), 4) -- Center should be visible
    lu.assertEquals(fow_memory.get_visibility(1, 1), 1) -- Distant tile should have memory level visibility
end

function test_fow_reveal:test_reveal_around_uses_traditional_mode()
    -- Ensure field of view mode is disabled
    fow_config.field_of_view_mode = false

    -- Reveal around position
    local changed = fow_reveal.reveal_around({ x = 5, y = 5 })

    -- Verify traditional mode was used
    lu.assertTrue(changed)
    lu.assertEquals(fow_memory.get_visibility(5, 5), 4) -- Center should be visible
    lu.assertNotEquals(fow_memory.get_visibility(5, 6), 0) -- Adjacent tile should have some visibility
end

function test_fow_reveal:test_set_field_of_view_mode()
    -- Enable field of view mode
    local changed = fow_reveal.set_field_of_view_mode(true)

    -- Verify mode was changed
    lu.assertTrue(changed)
    lu.assertTrue(fow_config.field_of_view_mode)
end

return test_fow_reveal 
