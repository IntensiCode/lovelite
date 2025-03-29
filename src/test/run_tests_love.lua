require("src.libraries.luaunit")
require("src.base.log")

-- Test runner module
local runner = {}

-- Find all test files in the test directory
function runner.find_test_files()
    local test_files = {}
    local items = love.filesystem.getDirectoryItems("src/test")
    
    for _, item in ipairs(items) do
        -- Only include Lua files that start with "test_" or end with "_test"
        local is_test = item:match("^test_.+%.lua$") or item:match("^.+_test%.lua$")
        
        -- Skip this file and the standard runner
        if is_test and item ~= "run_tests.lua" and item ~= "run_tests_love.lua" then
            table.insert(test_files, item)
        end
    end
    
    return test_files
end

-- Load a test file and map its test classes to the file
function runner.load_test_file(file_name, test_class_to_file)
    -- Get the module path for require
    local test_path = "src.test." .. file_name:gsub("%.lua$", "")
    
    -- Record existing test classes before loading the file
    local before = {}
    for k, v in pairs(_G) do
        if type(v) == "table" and k:match("^Test") then
            before[k] = true
        end
    end
    
    -- Require the test file
    require(test_path)
    
    -- Find new test classes that were added by this file
    local new_classes = {}
    for k, v in pairs(_G) do
        if type(v) == "table" and k:match("^Test") and not before[k] then
            test_class_to_file[k] = file_name
            table.insert(new_classes, k)
            log.debug("Found test class " .. k .. " in file " .. file_name)
        end
    end
    
    return new_classes
end

-- Load all test files and build class-to-file mapping
function runner.load_test_files()
    local test_files = runner.find_test_files()
    local test_class_to_file = {}
    
    for _, file_name in ipairs(test_files) do
        runner.load_test_file(file_name, test_class_to_file)
        log.debug("Loaded test file: " .. file_name)
    end
    
    log.info("Total test files loaded: " .. #test_files)
    return test_files, test_class_to_file
end

-- Run a single test method
function runner.run_test_method(test_class, method_name, method, results)
    results.tests_run = results.tests_run + 1
    
    local success, err = pcall(method, test_class)
    if success then
        results.passed = results.passed + 1
        log.debug("PASS: " .. test_class._NAME .. "." .. method_name)
    else
        results.failures = results.failures + 1
        log.error("FAIL: " .. test_class._NAME .. "." .. method_name)
        log.error("  " .. tostring(err))
    end
    
    return success
end

-- Run all tests in a test class
function runner.run_test_class(class_name, class_obj, test_class_to_file, executed_files, results)
    -- Get the file name for this test class
    local file_name = test_class_to_file[class_name]
    
    -- Log the file name if we haven't executed it yet
    if file_name and not executed_files[file_name] then
        log.info("Running tests from: " .. file_name)
        executed_files[file_name] = true
        results.current_file = file_name
    end
    
    -- Store the class name for better error reporting
    class_obj._NAME = class_name
    
    -- Run all test methods in this class
    for method_name, method in pairs(class_obj) do
        if type(method) == "function" and method_name:match("^test") then
            runner.run_test_method(class_obj, method_name, method, results)
        end
    end
end

-- Execute all test classes and methods
function runner.execute_tests(test_class_to_file)
    -- Test results storage
    local results = {
        tests_run = 0,
        failures = 0,
        errors = 0,
        passed = 0,
        current_file = nil
    }
    
    -- Track which files have been executed
    local executed_files = {}
    
    -- Find and run all test classes
    for class_name, class_obj in pairs(_G) do
        if type(class_obj) == "table" and class_name:match("^Test") then
            runner.run_test_class(class_name, class_obj, test_class_to_file, executed_files, results)
        end
    end
    
    return results
end

-- Print test summary
function runner.print_summary(results)
    log.info("-------------------------------------")
    log.info(string.format("Test Summary: %d tests, %d passed, %d failures, %d errors",
                     results.tests_run, 
                     results.passed,
                     results.failures, 
                     results.errors))
    
    local success = results.failures == 0 and results.errors == 0
    
    if success then
        log.info("ALL TESTS PASSED")
    else
        log.error("TEST SUITE FAILED")
    end
    log.info("-------------------------------------")
    
    return success
end

-- Main entry point: run all test files and return success status
function runner.run()
    log.info("Starting test suite...")
    
    -- Load all test files
    local _, test_class_to_file = runner.load_test_files()
    
    -- Run all tests
    local results = runner.execute_tests(test_class_to_file)
    
    -- Print summary and return success status
    return runner.print_summary(results)
end

return runner 