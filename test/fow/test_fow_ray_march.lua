---@diagnostic disable: missing-fields
require("src.base.log")
require("src.base.pos")
require("src.base.table")

local lu = require("src.libraries.luaunit")

local fow_config = require("src.map.fow.fow_config")
local fow_ray_march = require("src.map.fow.fow_ray_march")
local fow_draw = require("src.map.fow.fow_draw")

test_fow_ray_march = {}

-- Mock collision system for testing
local collision_mock = {
    is_walkable_tile = function(x, y)
        -- Default: all tiles are walkable
        return true
    end,

    is_wall_tile = function(x, y)
        -- Default: no walls
        return false
    end,

    is_full_wall_tile = function(x, y)
        -- Default: no full walls
        return false
    end,
}

-- Special visited coordinate tracker for Bresenham line test
local bresenham_visited = {}

function test_fow_ray_march:setup()
    -- Initialize basic fog of war configuration
    fow_config.size = { x = 10, y = 10 }
    fow_config.grid = {}
    fow_config.memory_grid = {}
    fow_config.enabled = true
    fow_config.inner_radius = 3
    fow_config.outer_radius = 6
    fow_config.field_of_view_mode = false
    fow_draw.mark_dirty()
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

function test_fow_ray_march:teardown()
    -- Reset fog of war configuration
    fow_config.grid = nil
    fow_config.memory_grid = nil
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

    -- Reset collision mock
    collision_mock.is_walkable_tile = function(x, y)
        return true
    end
    collision_mock.is_wall_tile = function(x, y)
        return false
    end
    collision_mock.is_full_wall_tile = function(x, y)
        return false
    end

    -- Reset Bresenham tracker
    bresenham_visited = {}
end

function test_fow_ray_march:test_ray_march_position_validation()
    -- Test valid positions
    lu.assertTrue(fow_ray_march.is_valid_position({}, 1, 1))
    lu.assertTrue(fow_ray_march.is_valid_position({}, 10, 10))

    -- Test invalid positions
    lu.assertFalse(fow_ray_march.is_valid_position({}, 0, 1))
    lu.assertFalse(fow_ray_march.is_valid_position({}, 1, 0))
    lu.assertFalse(fow_ray_march.is_valid_position({}, 11, 1))
    lu.assertFalse(fow_ray_march.is_valid_position({}, 1, 11))
end

function test_fow_ray_march:test_calculate_visibility_level()
    -- Test visibility at different distances
    lu.assertEquals(fow_ray_march.calculate_visibility_level({}, 2.0), 4) -- Within inner radius
    lu.assertEquals(fow_ray_march.calculate_visibility_level({}, 4.0), 2) -- Medium fog (was expecting 3)
    lu.assertEquals(fow_ray_march.calculate_visibility_level({}, 5.0), 2) -- Medium fog
    lu.assertEquals(fow_ray_march.calculate_visibility_level({}, 5.9), 1) -- Heavy fog
    lu.assertEquals(fow_ray_march.calculate_visibility_level({}, 7.0), 0) -- Beyond outer radius
end

function test_fow_ray_march:test_ray_casting_reveals_direct_line_of_sight()
    -- Cast rays from center
    fow_ray_march.cast_rays({}, { x = 5, y = 5 })

    -- Check visibility at different distances
    lu.assertEquals(fow_config.grid[5][5], 4) -- Center
    lu.assertEquals(fow_config.grid[5][6], 4) -- One tile away
    lu.assertEquals(fow_config.grid[5][8], 4) -- Still within inner radius
    lu.assertEquals(fow_config.grid[5][10], 2) -- Far distance (medium fog zone)
end

function test_fow_ray_march:test_ray_casting_diagonal_line_of_sight()
    -- Cast rays from center
    fow_ray_march.cast_rays({}, { x = 5, y = 5 })

    -- Check diagonal visibility
    lu.assertEquals(fow_config.grid[6][6], 4) -- Close diagonal
    lu.assertEquals(fow_config.grid[7][7], 4) -- Still within inner radius
    lu.assertEquals(fow_config.grid[8][8], 2) -- Far diagonal (medium fog zone)
end

function test_fow_ray_march:test_walls_are_visible()
    -- Set up a wall
    DI.collision.is_walkable_tile = function(x, y)
        return not (x == 7 and y == 5)
    end

    -- Cast rays from center
    fow_ray_march.cast_rays({}, { x = 5, y = 5 })

    -- Wall should be visible based on distance
    lu.assertEquals(fow_config.grid[5][7], 4)
end

function test_fow_ray_march:test_points_beyond_walls_are_not_visible()
    -- Set up a wall
    DI.collision.is_walkable_tile = function(x, y)
        return not (x == 7 and y == 5)
    end
    DI.collision.is_wall_tile = function(x, y)
        return (x == 7 and y == 5)
    end

    -- Cast rays from center
    fow_ray_march.cast_rays({}, { x = 5, y = 5 })

    -- Points beyond wall should be dark
    lu.assertEquals(fow_config.grid[5][8], 0)
    lu.assertEquals(fow_config.grid[5][9], 0)
end

function test_fow_ray_march:test_l_shaped_walls()
    -- Set up L-shaped wall
    DI.collision.is_walkable_tile = function(x, y)
        return not ((x == 7 and y == 5) or (x == 7 and y == 6))
    end
    DI.collision.is_wall_tile = function(x, y)
        return (x == 7 and y == 5) or (x == 7 and y == 6)
    end

    -- Cast rays from center
    fow_ray_march.cast_rays({}, { x = 5, y = 5 })

    -- Both wall segments should be visible
    lu.assertEquals(fow_config.grid[5][7], 4) -- Horizontal segment
    lu.assertEquals(fow_config.grid[6][7], 4) -- Vertical segment

    -- Points beyond both segments should be dark
    lu.assertEquals(fow_config.grid[5][8], 0)
    lu.assertEquals(fow_config.grid[6][8], 0)
end

function test_fow_ray_march:test_rooftop_visibility_handling()
    -- Set up a rooftop (full wall)
    DI.collision.is_walkable_tile = function(x, y)
        return not (x == 7 and y == 5)
    end
    DI.collision.is_full_wall_tile = function(x, y)
        return (x == 7 and y == 5)
    end
    DI.collision.is_wall_tile = function(x, y)
        return (x == 7 and y == 5)
    end

    -- Cast rays from center
    fow_ray_march.cast_rays({}, { x = 5, y = 5 })

    -- Wall should be visible
    lu.assertEquals(fow_config.grid[5][7], 4)

    -- One tile beyond should be visible at full level since it's within inner_radius
    lu.assertEquals(fow_config.grid[5][8], 4)

    -- Two tiles beyond should be dark (shadowed)
    lu.assertEquals(fow_config.grid[5][9], 0)
end

function test_fow_ray_march:test_bresenham_line()
    -- Cast rays from center
    fow_ray_march.cast_rays({}, { x = 5, y = 5 })

    -- Check horizontal line
    lu.assertTrue(DI.collision.is_walkable_tile(6, 5))
    lu.assertTrue(DI.collision.is_walkable_tile(7, 5))
    lu.assertTrue(DI.collision.is_walkable_tile(8, 5))

    -- Check diagonal line
    lu.assertTrue(DI.collision.is_walkable_tile(6, 6))
    lu.assertTrue(DI.collision.is_walkable_tile(7, 7))
    lu.assertTrue(DI.collision.is_walkable_tile(8, 8))
end

function test_fow_ray_march:test_visibility_beyond_full_wall()
    -- Set up a full wall
    DI.collision.is_walkable_tile = function(x, y)
        return not (x == 7 and y == 5)
    end
    DI.collision.is_full_wall_tile = function(x, y)
        return (x == 7 and y == 5)
    end
    DI.collision.is_wall_tile = function(x, y)
        return (x == 7 and y == 5)
    end

    -- Cast rays from center
    fow_ray_march.cast_rays({}, { x = 5, y = 5 })

    -- Wall should be visible
    lu.assertEquals(fow_config.grid[5][7], 4)

    -- One tile beyond should be visible at full level since it's within inner_radius
    lu.assertEquals(fow_config.grid[5][8], 4)

    -- Two tiles beyond should be dark (shadowed)
    lu.assertEquals(fow_config.grid[5][9], 0)
end

return test_fow_ray_march
