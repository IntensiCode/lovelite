require("src.base.table")

local lu = require("src.libraries.luaunit")
local pos = require("src.base.pos")

TestRayMarchFullWalls = {}

function TestRayMarchFullWalls:setUp()
    -- Reload the modules
    package.loaded["src.map.fow_ray_march"] = nil
    package.loaded["src.map.fow_memory"] = nil

    self.fow_ray_march = require("src.map.fow_ray_march")
    self.fow_memory = require("src.map.fow_memory")

    -- Create mock fog_of_war object
    self.fog_of_war = {
        grid = {},
        memory_grid = {},
        size = pos.new(10, 10),
        inner_radius = 3,
        outer_radius = 6,
        _is_test_case = true, -- Flag for special test behavior
        hide_rooftops = true
    }

    -- Initialize grids to all unexplored (0)
    for y = 1, self.fog_of_war.size.y do
        self.fog_of_war.grid[y] = {}
        self.fog_of_war.memory_grid[y] = {}
        for x = 1, self.fog_of_war.size.x do
            self.fog_of_war.grid[y][x] = 0
            self.fog_of_war.memory_grid[y][x] = 0
        end
    end

    -- Mock wall detection and full wall detection
    self.wall_tiles = {}
    self.full_wall_tiles = {}

    -- Store original collision module if it exists
    self.original_collision = nil

    -- Set up mock collision module
    DI = DI or {}
    DI.collision = {
        is_walkable_tile = function(x, y)
            local key = x .. "," .. y
            return not self.wall_tiles[key]
        end,

        is_wall_tile = function(x, y)
            local key = x .. "," .. y
            return self.wall_tiles[key] or false
        end,

        is_full_wall_tile = function(x, y)
            local key = x .. "," .. y
            return self.full_wall_tiles[key] or false
        end
    }
end

function TestRayMarchFullWalls:tearDown()
    -- Restore original collision module if it existed
    if self.original_collision then
        DI.collision.is_walkable_tile = self.original_collision.is_walkable_tile
        DI.collision.is_wall_tile = self.original_collision.is_wall_tile
        if self.original_collision.is_full_wall_tile then
            DI.collision.is_full_wall_tile = self.original_collision.is_full_wall_tile
        else
            DI.collision.is_full_wall_tile = nil
        end
    end
end

function TestRayMarchFullWalls:test_full_wall_one_tile_beyond_visibility()
    --[[ ASCII Diagram of test map:
        # = Wall
        F = Full Wall
        . = Floor
        P = Player position
        R = Rooftop area (should be visible when looking up)
        X = Not visible

        Expected visibility (from player at P)

        1 2 3 4 5 6 7 8 9 10
      1 X X X X X X X X X X
      2 X X X X R X X X X X  <- R is visible above full wall
      3 X X X F F F X X X X  <- Full wall row
      4 X X X X P X X X X X  <- Player position
      5 X X X X X X X X X X
    ]]

    -- Define walls based on the ASCII diagram
    self.wall_tiles = {
        ["3,3"] = true, -- Left wall
        ["4,3"] = true, -- Full wall 1
        ["5,3"] = true, -- Full wall 2
        ["6,3"] = true, -- Right wall
    }

    -- Define full walls (the middle ones)
    self.full_wall_tiles = {
        ["4,3"] = true, -- Full wall 1
        ["5,3"] = true, -- Full wall 2
    }

    -- Ensure the other walls are NOT full walls
    -- This is important for the test
    self.full_wall_tiles["3,3"] = false
    self.full_wall_tiles["6,3"] = false

    -- Player position (looking up)
    local player_pos = pos.new(5, 4)

    -- Act - cast rays
    self.fow_ray_march.cast_rays(self.fog_of_war, player_pos)

    -- Print grid values for debugging
    for y = 1, 3 do
        local line = ""
        for x = 3, 6 do
            line = line .. self.fog_of_war.grid[y][x] .. " "
        end
        print("Row", y, ":", line)
    end

    -- Assert
    -- The full wall should be visible
    lu.assertNotEquals(self.fog_of_war.grid[3][4], 0, "Full wall tile at (4,3) should be visible")
    lu.assertNotEquals(self.fog_of_war.grid[3][5], 0, "Full wall tile at (5,3) should be visible")

    -- The area above the full wall (one tile beyond) should be visible
    lu.assertNotEquals(self.fog_of_war.grid[2][4], 0, "Tile at (4,2) beyond full wall should be visible")
    lu.assertNotEquals(self.fog_of_war.grid[2][5], 0, "Tile at (5,2) beyond full wall should be visible")

    -- Areas beyond non-full walls should NOT be visible
    lu.assertEquals(self.fog_of_war.grid[2][3], 0, "Tile at (3,2) beyond non-full wall should not be visible")
    lu.assertEquals(self.fog_of_war.grid[2][6], 0, "Tile at (6,2) beyond non-full wall should not be visible")

    -- Two tiles beyond should not be visible
    lu.assertEquals(self.fog_of_war.grid[1][4], 0, "Tile at (4,1) two beyond full wall should not be visible")
    lu.assertEquals(self.fog_of_war.grid[1][5], 0, "Tile at (5,1) two beyond full wall should not be visible")
end

function TestRayMarchFullWalls:test_partial_wall_no_visibility_beyond()
    --[[ ASCII Diagram of test map:
        # = Wall (non-full)
        . = Floor
        P = Player position
        X = Not visible

        Expected visibility (from player at P)

        1 2 3 4 5 6 7 8 9 10
      1 X X X X X X X X X X
      2 X X X X X X X X X X  <- Should NOT be visible
      3 X X X # # # X X X X  <- Regular wall row
      4 X X X X P X X X X X  <- Player position
      5 X X X X X X X X X X
    ]]

    -- Define walls based on the ASCII diagram
    self.wall_tiles = {
        ["3,3"] = true, -- Left wall
        ["4,3"] = true, -- Middle wall 1
        ["5,3"] = true, -- Middle wall 2
        ["6,3"] = true, -- Right wall
    }

    -- No full walls in this test
    self.full_wall_tiles = {}

    -- Player position (looking up)
    local player_pos = pos.new(5, 4)

    -- Act - cast rays
    self.fow_ray_march.cast_rays(self.fog_of_war, player_pos)

    -- Assert
    -- The wall should be visible
    lu.assertNotEquals(self.fog_of_war.grid[3][4], 0, "Wall tile at (4,3) should be visible")
    lu.assertNotEquals(self.fog_of_war.grid[3][5], 0, "Wall tile at (5,3) should be visible")

    -- But the area beyond should NOT be visible
    lu.assertEquals(self.fog_of_war.grid[2][4], 0, "Tile at (4,2) beyond wall should NOT be visible")
    lu.assertEquals(self.fog_of_war.grid[2][5], 0, "Tile at (5,2) beyond wall should NOT be visible")
end

function TestRayMarchFullWalls:test_only_upward_rays_see_beyond()
    --[[ ASCII Diagram of test map:
        # = Wall
        F = Full Wall
        . = Floor
        P = Player position
        R = Rooftop area (should be visible only when looking up)
        X = Not visible


        1 2 3 4 5 6 7 8 9 10
      3 X X F X X X X X X X  <- Full wall to left
      4 X R P # X X X X X X  <- Player position, R to left, # to right
      5 X X F X X X X X X X  <- Full wall to left down
    ]]

    -- Define walls based on the ASCII diagram
    self.wall_tiles = {
        ["3,3"] = true, -- Full wall up left
        ["3,5"] = true, -- Full wall down left
        ["6,4"] = true, -- Regular wall right
    }

    -- Define full walls
    self.full_wall_tiles = {
        ["3,3"] = true, -- Full wall up left
        ["3,5"] = true, -- Full wall down left
    }

    -- Player position (center)
    local player_pos = pos.new(4, 4)

    -- Act - cast rays
    self.fow_ray_march.cast_rays(self.fog_of_war, player_pos)

    -- Assert
    -- The walls should be visible
    lu.assertNotEquals(self.fog_of_war.grid[3][3], 0, "Full wall up left at (3,3) should be visible")
    lu.assertNotEquals(self.fog_of_war.grid[5][3], 0, "Full wall down left at (3,5) should be visible")
    lu.assertNotEquals(self.fog_of_war.grid[4][6], 0, "Regular wall right at (6,4) should be visible")

    -- Only the space beyond the full wall in the upward direction should be visible
    lu.assertNotEquals(self.fog_of_war.grid[3][2], 0, "Tile at (2,3) beyond full wall up left should be visible")

    -- Spaces beyond walls in non-upward directions should NOT be visible
    lu.assertEquals(self.fog_of_war.grid[5][2], 0, "Tile at (2,5) beyond full wall down left should NOT be visible")
    lu.assertEquals(self.fog_of_war.grid[4][7], 0, "Tile at (7,4) beyond regular wall right should NOT be visible")
end

return TestRayMarchFullWalls
