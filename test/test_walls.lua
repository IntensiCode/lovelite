-- TODO Tell me, do we need these two? is main.lua not already loading them? and they are globals, right?
require("src.base.pos")
require("src.base.table")

local lu = require("src.libraries.luaunit")

-- Define the TestWalls class
TestWalls = {}

-- Setup mock objects for each test
function TestWalls:setUp()
    -- Create a mock dungeon module
    self.dungeon = {
        map = {
            width = 10,
            height = 10,
            layers = {},
            tileheight = 16,
            tilewidth = 16
        }
    }

    -- Create a mock collision module
    self.collision = {
        is_walkable_tile = function(x, y)
            -- Default implementation that will be overridden in tests
            return true
        end,

        is_wall_tile = function(x, y)
            -- Default implementation that will be overridden in tests
            return not self.collision.is_walkable_tile(x, y)
        end
    }

    -- Save the original DI if it exists
    self.original_DI = DI

    -- Set up our mocks in the dependency injection system
    DI = {
        dungeon = self.dungeon,
        collision = self.collision
    }

    -- Reload the walls module to test
    package.loaded["src.map.walls"] = nil
    self.walls = require("src.map.walls")
end

-- Cleanup after each test
function TestWalls:tearDown()
    -- Restore the original DI
    DI = self.original_DI
end

-- Shared helper function to set up walkable tiles from an ASCII diagram
function TestWalls:setupWalkableMapFromAscii(ascii_diagram)
    -- Split the diagram into lines and remove any trailing/leading whitespace
    local lines = {}
    for line in ascii_diagram:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Create walkable map grid from ASCII
    local grid = {}
    for y, line in ipairs(lines) do
        grid[y] = {}
        for x = 1, #line do
            local char = line:sub(x, x)
            -- ONLY '.' represents walkable floor, anything else is a wall
            -- '_' and 'F' were being treated as walls in previous tests
            grid[y][x] = (char == '.') and 1 or 0
        end
    end

    -- Set dimensions
    self.dungeon.map.height = #grid
    self.dungeon.map.width = #grid[1]
    self.walkable_map = grid

    -- Override the is_walkable_tile function
    self.collision.is_walkable_tile = function(x, y)
        -- Handle out-of-bounds checks
        if x < 1 or x > self.dungeon.map.width or y < 1 or y > self.dungeon.map.height then
            return false
        end
        -- 1 represents walkable, 0 represents wall
        return self.walkable_map[y][x] == 1
    end
end

-- Shared helper function to visualize full wall detection
function TestWalls:visualizeFullWallDetection()
    local full_wall_tiles = self.walls.full_wall_tiles
    local visualized_map = {}

    for y = 1, self.dungeon.map.height do
        visualized_map[y] = {}
        for x = 1, self.dungeon.map.width do
            local key = x .. "," .. y
            if self.walkable_map[y][x] == 1 then
                visualized_map[y][x] = "." -- Floor
            elseif full_wall_tiles[key] then
                visualized_map[y][x] = "F" -- Full wall
            else
                visualized_map[y][x] = "W" -- Regular wall
            end
        end
    end

    -- Print the visualized map
    log.debug("Visualized full wall detection:")
    for y = 1, self.dungeon.map.height do
        log.debug(table.concat(visualized_map[y]))
    end
end

-- Test each of the 16 possible patterns for full wall detection
function TestWalls:test_pattern_1()
    local ascii_diagram = [[
WWW
WFW
...
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Check if the center tile is walkable (should be false)
    log.debug("Center tile (2,2) walkable:", self.collision.is_walkable_tile(2, 2))
    -- Check if tile below is walkable (should be true)
    log.debug("Tile below (2,3) walkable:", self.collision.is_walkable_tile(2, 3))
    -- Check left and right walls
    log.debug("Left tile (1,2) is wall:", not self.collision.is_walkable_tile(1, 2))
    log.debug("Right tile (3,2) is wall:", not self.collision.is_walkable_tile(3, 2))

    -- Call the function directly and print result
    local result = self.walls.is_full_wall_tile(2, 2)
    log.debug("is_full_wall_tile result:", result)

    -- Check if the center tile is a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Pattern 1 should identify center as a full wall")
end

function TestWalls:test_pattern_2()
    local ascii_diagram = [[
WW.
WFW
...
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Check if the center tile is a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Pattern 2 should identify center as a full wall")
end

function TestWalls:test_pattern_3()
    local ascii_diagram = [[
.WW
WFW
...
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Check if the center tile is a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Pattern 3 should identify center as a full wall")
end

function TestWalls:test_pattern_4()
    local ascii_diagram = [[
.W.
WFW
...
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Check if the center tile is a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Pattern 4 should identify center as a full wall")
end

function TestWalls:test_pattern_5()
    local ascii_diagram = [[
WWW
WFW
..W
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Check if the center tile is a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Pattern 5 should identify center as a full wall")
end

function TestWalls:test_pattern_6()
    local ascii_diagram = [[
WWW
WFW
W..
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Check if the center tile is a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Pattern 6 should identify center as a full wall")
end

function TestWalls:test_pattern_7()
    -- First test with no walkable tile below (should fail)
    local ascii_diagram = [[
WWW
WFW
WWW
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- This should NOT be a full wall since there's no walkable tile below
    lu.assertFalse(self.walls.is_full_wall_tile(2, 2),
        "Pattern 7 should not identify center as a full wall (no floor below)")

    -- Correct the pattern for test by adding a walkable tile below
    ascii_diagram = [[
WWW
WFW
W.W
]]

    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Now it should be a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Corrected Pattern 7 should identify center as a full wall")
end

function TestWalls:test_pattern_8()
    local ascii_diagram = [[
WW.
WFW
..W
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Check if the center tile is a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Pattern 8 should identify center as a full wall")
end

function TestWalls:test_pattern_9()
    local ascii_diagram = [[
WW.
WFW
W..
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Check if the center tile is a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Pattern 9 should identify center as a full wall")
end

function TestWalls:test_pattern_10()
    -- First test with no walkable tile below (should fail)
    local ascii_diagram = [[
WW.
WFW
WWW
]]

    -- Setup the walkable map with a 3x3 grid centered on the test tile
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- This should NOT be a full wall since there's no walkable tile below
    lu.assertFalse(self.walls.is_full_wall_tile(2, 2),
        "Pattern 10 should not identify center as a full wall (no floor below)")

    -- Correct the pattern for test by adding a walkable tile below
    ascii_diagram = [[
WW.
WFW
W.W
]]

    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Now it should be a full wall
    lu.assertTrue(self.walls.is_full_wall_tile(2, 2), "Corrected Pattern 10 should identify center as a full wall")
end

function TestWalls:test_pattern_11_through_16()
    -- Define patterns with ASCII diagrams
    local patterns = {
        -- Pattern 11: .WW, WFW, ..W
        { [[
.WW
WFW
..W
]], true },

        -- Pattern 12: .WW, WFW, W..
        { [[
.WW
WFW
W..
]], true },

        -- Pattern 13: .WW, WFW, W.W - requires floor below
        { [[
.WW
WFW
W.W
]], true },

        -- Pattern 14: .W., WFW, ..W
        { [[
.W.
WFW
..W
]], true },

        -- Pattern 15: .W., WFW, W..
        { [[
.W.
WFW
W..
]], true },

        -- Pattern 16: .W., WFW, W.W - requires floor below
        { [[
.W.
WFW
W.W
]], true }
    }

    -- Test each pattern
    for i, pattern in ipairs(patterns) do
        -- Setup the walkable map with the ASCII diagram
        self:setupWalkableMapFromAscii(pattern[1])

        -- Check if the center tile is a full wall
        local result = self.walls.is_full_wall_tile(2, 2)
        lu.assertEquals(result, pattern[2], "Pattern " .. (i + 10) .. " should give expected result")
    end
end

function TestWalls:test_counter_examples()
    -- Test cases where the center tile should NOT be a full wall
    local counter_examples = {
        -- No wall to the left
        [[
WWW
.FW
...
]],

        -- No wall to the right
        [[
WWW
WF.
...
]],

        -- No floor below
        [[
WWW
WFW
WWW
]],

        -- Center is not a wall (walkable)
        [[
WWW
W.W
...
]]
    }

    -- Test each counter example
    for i, example in ipairs(counter_examples) do
        -- Setup the walkable map with the ASCII diagram
        self:setupWalkableMapFromAscii(example)

        -- Check that the center tile is NOT a full wall
        local result = self.walls.is_full_wall_tile(2, 2)
        lu.assertFalse(result, "Counter example " .. i .. " should NOT be identified as a full wall")
    end
end

-- Shared helper function to parse expected results from ASCII diagram
function TestWalls:make_expected(expected_result)
    local expected_full_walls = {}
    local lines = {}
    for line in expected_result:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    for y, line in ipairs(lines) do
        for x = 1, #line do
            local char = line:sub(x, x)
            if char == "F" then
                expected_full_walls[x .. "," .. y] = true
            end
        end
    end

    return expected_full_walls
end

-- Shared helper function to verify expected full wall tiles
function TestWalls:verify_expected(expected_full_walls)
    for key, _ in pairs(expected_full_walls) do
        local x, y = key:match("(%d+),(%d+)")
        x, y = tonumber(x), tonumber(y)
        lu.assertTrue(self.walls.full_wall_tiles[key], "Tile at (" .. x .. "," .. y .. ") should be a full wall")
    end
end

function TestWalls:test_horizontal_wall_detection()
    -- Input walkable map
    local ascii_diagram = [[
WWWWW
WWWWW
.....
.....
.....
]]

    -- Expected full wall detection result - All walls in the second row that have walls on both sides
    -- The implementation considers edge tiles as full walls too if they have a floor below and a wall to one side
    local expected_result = [[
WWWWW
FFFFF
.....
.....
.....
]]

    -- Setup the walkable map
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Act
    self.walls.identify_full_wall_tiles()

    -- Visualize for debugging
    self:visualizeFullWallDetection()

    -- Parse and verify expected results
    local expected_full_walls = self:make_expected(expected_result)
    self:verify_expected(expected_full_walls)

    -- Row 1 should not have full walls (no floor below)
    for x = 1, 5 do
        lu.assertFalse(self.walls.full_wall_tiles[x .. ",1"] or false,
            "Tile at (" .. x .. ",1) should not be a full wall (no floor below)")
    end
end

function TestWalls:test_multiple_horizontal_segments()
    -- Input walkable map
    local ascii_diagram = [[
WWWWWWWWWW
WWW....WWW
..........
..........
..........
]]

    -- Expected full wall detection result
    local expected_result = [[
WWWFFFFWWW
FFW....WFF
..........
..........
..........
]]

    -- Setup the walkable map
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Act
    self.walls.identify_full_wall_tiles()

    -- Visualize for debugging
    self:visualizeFullWallDetection()

    -- Parse and verify expected results
    local expected_full_walls = self:make_expected(expected_result)
    self:verify_expected(expected_full_walls)
end

function TestWalls:test_room_with_corridor()
    -- Input walkable map
    local ascii_diagram = [[
WWWWWWWWW
W......WW
W......WW
WWWW.WWWW
WWWW.WWWW
WWWW.WWWW
WWWW.WWWW
WWWW.WWWW
WWWWWWWWW
]]

    -- Expected full wall detection result
    local expected_result = [[
WFFFFFFWW
W......WW
W......WW
WWWW.WWWW
WWWW.WWWW
WWWW.WWWW
WWWW.WWWW
WWWW.WWWW
WWWWWWWWW
]]

    -- Setup the walkable map with the ASCII diagram
    self:setupWalkableMapFromAscii(ascii_diagram)

    -- Act
    self.walls.identify_full_wall_tiles()

    -- Visualize for debugging
    self:visualizeFullWallDetection()

    -- Assert
    local expected_full_walls = self:make_expected(expected_result)
    self:verify_expected(expected_full_walls)
end

return TestWalls
