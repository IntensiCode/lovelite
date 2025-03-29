-- Add src directory to the Lua path
package.path = "src/?.lua;src/?/init.lua;" .. package.path

local lu = require("src.libraries.luaunit")

-- Automatically load all test files from the test directory
local function load_test_files()
    local test_count = 0
    
    -- Get all files in the test directory
    local function get_files(dir)
        local files = {}
        local p = io.popen('find "' .. dir .. '" -type f -name "*.lua"')
        for file in p:lines() do
            table.insert(files, file)
        end
        p:close()
        return files
    end
    
    local test_files = get_files("src/test")
    
    for _, file_path in ipairs(test_files) do
        -- Only load Lua files that start with "test_" or end with "_test"
        local filename = file_path:match("[^/]+%.lua$")
        local is_test = filename:match("^test_.+%.lua$") or filename:match("^.+_test%.lua$")
        
        if is_test and filename ~= "run_tests.lua" then
            local module_path = file_path:gsub("%.lua$", ""):gsub("/", ".")
            require(module_path)
            test_count = test_count + 1
            print("Loaded test: " .. module_path)
        end
    end
    
    return test_count
end

local test_count = load_test_files()
print("Total test files loaded: " .. test_count)

-- Run all tests
os.exit(lu.LuaUnit.run()) 