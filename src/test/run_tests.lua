require("src.base.log")
require("src.base.math")
require("src.base.table")

local lu = require("src.libraries.luaunit")

-- Automatically load all test files from the test directory
local function load_test_files()
    local test_count = 0
    
    -- Get all files in the test directory
    local items = love.filesystem.getDirectoryItems("src/test")
    
    for _, item in ipairs(items) do
        -- Only load Lua files that start with "test_" or end with "_test"
        local is_test = item:match("^test_.+%.lua$") or item:match("^.+_test%.lua$")
        
        if is_test then
            local test_path = "src.test." .. item:gsub("%.lua$", "")
            require(test_path)
            test_count = test_count + 1
        end
    end
    
    return test_count
end

local test_count = load_test_files()
log.info("Loaded " .. test_count .. " tests")

-- Run all tests
return lu.LuaUnit.run() 