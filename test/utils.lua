local log = require("src.base.log")
local lu = require("src.libraries.luaunit")

local utils = {}

---Build a grid representation of visibility data for test verification
---@param visibility_data table The visibility data (either 2D array or key-value map)
---@param size table|nil Optional size parameter {x=number, y=number}
---@param symbol_map table|nil Optional mapping of values to symbols
---@return table grid Array of strings representing the grid
function utils.build_visibility_grid(visibility_data, size, symbol_map)
    -- Default symbol map for FOW visibility levels
    symbol_map = symbol_map or {
        [0] = ".",  -- Hidden
        [1] = "H",  -- Heavy fog
        [2] = "M",  -- Medium fog
        [3] = "L",  -- Light fog
        [4] = "V",  -- Visible
    }

    -- Determine grid dimensions
    local min_x, max_x = 1, 7  -- Default for visibility tests
    local min_y, max_y = 1, 7
    if size then
        min_x, max_x = 1, size.x
        min_y, max_y = 1, size.y
    end

    -- Build grid with visible cells marked
    local grid = {}
    for y = min_y, max_y do
        local row = {}
        for x = min_x, max_x do
            -- Handle both 2D array and key-value map formats
            local level
            if visibility_data[y] and visibility_data[y][x] then
                -- 2D array format
                level = visibility_data[y][x]
            else
                -- Key-value map format
                level = visibility_data[y .. "," .. x]
            end

            -- Map level to symbol, use "?" for nil (points not reached by any ray)
            local symbol
            if level == nil then
                symbol = "?"
            else
                symbol = symbol_map[level]
                assert(symbol, string.format(
                    "Invalid visibility level %s at (%d,%d)",
                    tostring(level), x, y
                ))
            end
            row[#row + 1] = symbol
        end
        grid[y] = table.concat(row, " ")
    end
    return grid
end

---Compare expected (multiline string) with actual (grid array) visibility results
---@param expected string Multiline string with expected grid pattern
---@param actual table Array of strings representing actual grid
function utils.verify_visibility_grid(expected, actual)
    -- Convert expected string to table of lines for comparison
    local expected_lines = {}
    for line in expected:gmatch("[^\n]+") do
        -- Strip comments from expected lines
        local line_without_comment = line:gsub("%-%-.*$", "")
        -- Trim whitespace
        table.insert(expected_lines, line_without_comment:match("^(.-)%s*$"))
    end

    -- Compare row by row
    local comparison_results = {}
    local any_failed = false
    for y = 1, #expected_lines do
        if actual[y] == expected_lines[y] then
            comparison_results[y] = "OK"
        else
            comparison_results[y] = "FAIL"
            any_failed = true
        end
    end

    -- If any line failed, report all results and fail the test
    if any_failed then
        local failure_report = {}
        local failed_lines_count = 0
        for y = 1, #expected_lines do
            table.insert(failure_report, string.format("  Line %d: %s", y, comparison_results[y]))
            if comparison_results[y] == "FAIL" then
                failed_lines_count = failed_lines_count + 1
            end
        end

        -- Pre-build actual grid string for potential logging
        local actual_grid_str = table.concat(actual, "\n")

        log.debug("Visibility grid verification failed. Actual grid:")
        log.debug("\n" .. actual_grid_str)
        log.debug("Line comparison results:")
        log.debug(table.concat(failure_report, "\n"))

        lu.fail(
            string.format(
                "Visibility grid mismatch. %d out of %d lines failed.",
                failed_lines_count,
                #expected_lines
            )
        )
    end
end

return utils 