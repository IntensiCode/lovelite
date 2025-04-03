require("src.base.table")

local lu = require("src.libraries.luaunit")
local pos = require("src.base.pos")

-- Import the module to test
local movement_module_name = "src.player.movement"
local movement = require(movement_module_name)

-- Mock dependency: DI.collision
_G.DI = {}
DI.collision = {}

-- Mock class structure
test_player_movement = {}

function test_player_movement:setup()
    -- Reload the module to ensure clean state for each test
    package.loaded[movement_module_name] = nil
    movement = require(movement_module_name)

    -- Mock player object
    self.player = {
        pos = pos.new(5, 5),
        speed = 2,
        slow_time = nil,
        slow_factor = 0.5,
    }

    -- Store original functions to restore later
    self.original_collision_is_walkable = DI.collision.is_walkable
    self.original_collision_is_blocked_by_entity = DI.collision.is_blocked_by_entity
    self.original_collision_find_entity_slide = DI.collision.find_entity_slide

    -- Set up default mock behaviors
    DI.collision.is_walkable = function(opts)
        return true -- Default: everywhere is walkable
    end

    DI.collision.is_blocked_by_entity = function(opts)
        return false -- Default: no entity collisions
    end

    DI.collision.find_entity_slide = function(opts)
        return pos.new(opts.to.x, opts.to.y) -- Default: can slide anywhere
    end
end

function test_player_movement:teardown()
    -- Restore original functions
    DI.collision.is_walkable = self.original_collision_is_walkable
    DI.collision.is_blocked_by_entity = self.original_collision_is_blocked_by_entity
    DI.collision.find_entity_slide = self.original_collision_find_entity_slide
end

function test_player_movement:test_direct_movement_succeeds_when_path_clear()
    -- Arrange
    local input = pos.new(1, 0) -- Move right
    local dt = 1
    local expected_pos = pos.new(7, 5) -- 5 + 2*1*1 = 7 (x + speed*direction*dt)

    -- Mock collision functions - path is clear
    DI.collision.is_walkable = function(opts)
        return true
    end
    DI.collision.is_blocked_by_entity = function(opts)
        return false
    end

    -- Act
    movement.handle(self.player, input, dt)

    -- Assert
    lu.assertEquals(
        self.player.pos.x,
        expected_pos.x,
        "Player should move right when path is clear"
    )
    lu.assertEquals(self.player.pos.y, expected_pos.y, "Player y position should not change")
end

function test_player_movement:test_wall_sliding_horizontal_when_diagonal_blocked()
    -- Arrange
    --[[
        Wall layout:
        .....
        .....
        ..P#.  P=player, #=wall
        .....
        .....
    ]]
    local input = pos.new(1, 1) -- Move down-right diagonally
    local dt = 1

    -- Mock collisions - diagonal movement blocked, but horizontal works
    DI.collision.is_walkable = function(opts)
        -- Block diagonal movement and vertical, but allow horizontal
        if opts.y > 5 then
            return false
        end
        return true
    end

    -- Act
    movement.handle(self.player, input, dt)

    -- Assert - we expect the player to slide horizontally
    lu.assertEquals(
        self.player.pos.y,
        5,
        "Player y should not change when vertical path is blocked"
    )
    lu.assertTrue(
        self.player.pos.x > 5,
        "Player should slide right when diagonal path is blocked but horizontal is open"
    )
end

function test_player_movement:test_wall_sliding_vertical_when_diagonal_blocked()
    -- Arrange
    --[[
        Wall layout:
        .....
        .....
        ..P..  P=player
        ..#..  #=wall to the right
        .....
    ]]
    local input = pos.new(1, 1) -- Move down-right diagonally
    local dt = 1

    -- Mock collisions - diagonal movement blocked, horizontal blocked, but vertical open
    DI.collision.is_walkable = function(opts)
        -- Block horizontal movement but allow vertical
        if opts.x > 5 then
            return false
        end
        return true
    end

    -- Act
    movement.handle(self.player, input, dt)

    -- Assert - we expect the player to slide vertically
    lu.assertEquals(
        self.player.pos.x,
        5,
        "Player x should not change when horizontal path is blocked"
    )
    lu.assertTrue(
        self.player.pos.y > 5,
        "Player should slide down when diagonal path is blocked but vertical is open"
    )
end

function test_player_movement:test_entity_sliding_when_walls_not_blockable()
    -- Arrange
    --[[
        Entity layout:
        .....
        .....
        ..PE.  P=player, E=entity
        .....
        .....
    ]]
    local input = pos.new(1, 0) -- Move right
    local dt = 1
    local entity_pos = pos.new(6, 5)

    -- Mock collisions - entity blocking, but slide vertically is clear
    DI.collision.is_walkable = function(opts)
        return true
    end
    DI.collision.is_blocked_by_entity = function(opts)
        -- Entity at (6,5) - block direct path
        return math.abs(opts.x - entity_pos.x) < 0.9 and math.abs(opts.y - entity_pos.y) < 0.9
    end

    -- Create a slide position below the entity
    local slide_pos = pos.new(6, 6)
    DI.collision.find_entity_slide = function(opts)
        return slide_pos
    end

    -- Act
    movement.handle(self.player, input, dt)

    -- Assert - we only care that it successfully slid somewhere different
    lu.assertNotEquals(self.player.pos.x, 5, "Player should have moved from its starting position")
    lu.assertTrue(
        (self.player.pos - entity_pos):length() >= 0.9,
        "Player should have slid to avoid entity collision"
    )
end

function test_player_movement:test_slow_effect_reduces_movement_speed()
    -- Arrange
    local input = pos.new(1, 0) -- Move right
    local dt = 1
    self.player.slow_time = 2 -- Player is under slow effect
    local expected_speed = self.player.speed * self.player.slow_factor -- 2 * 0.5 = 1
    local expected_pos = pos.new(6, 5) -- 5 + 1*1*1 = 6 (x + modified_speed*direction*dt)

    -- Mock collision functions - path is clear
    DI.collision.is_walkable = function(opts)
        return true
    end
    DI.collision.is_blocked_by_entity = function(opts)
        return false
    end

    -- Act
    movement.handle(self.player, input, dt)

    -- Assert
    lu.assertEquals(
        self.player.pos.x,
        expected_pos.x,
        "Player should move at reduced speed when under slow effect"
    )
    lu.assertEquals(self.player.pos.y, expected_pos.y, "Player y position should not change")
end

function test_player_movement:test_no_movement_when_both_sliding_attempts_fail()
    -- Arrange
    --[[
        Layout (corner case):
        .....
        .###.
        .#P#.  P=player, #=wall
        .###.
        .....
    ]]
    local input = pos.new(1, 1) -- Try to move down-right diagonally
    local dt = 1
    local start_pos = pos.new(5, 5)
    self.player.pos = start_pos

    -- Mock collisions - blocked in all directions
    DI.collision.is_walkable = function(opts)
        -- Player is surrounded by walls
        return opts.x == 5 and opts.y == 5
    end
    DI.collision.is_blocked_by_entity = function(opts)
        return false
    end

    -- Act
    movement.handle(self.player, input, dt)

    -- Assert
    lu.assertEquals(
        self.player.pos.x,
        start_pos.x,
        "Player x should not change when movement blocked in all directions"
    )
    lu.assertEquals(
        self.player.pos.y,
        start_pos.y,
        "Player y should not change when movement blocked in all directions"
    )
end

-- Run tests
if not arg then
    arg = {}
end
if arg[1] == "test" then
    lu.LuaUnit.run("test_player_movement")
end

return test_player_movement
