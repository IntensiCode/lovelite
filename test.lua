require("src.libraries.luaunit")
require("src.base.log")

-- Test runner module
local runner = {}

-- Get file content to find line numbers for test methods
function runner.get_file_content(file_path)
    -- Try to read the file content
    local content = nil
    local file = io.open(file_path, "r")
    if file then
        content = file:read("*all")
        file:close()
    end
    return content
end

-- Find line number for a method in a file content
function runner.find_method_line_number(file_content, method_name)
    if not file_content then return nil end

    -- Look for "function TestClass:methodName" or similar patterns
    local pattern = "function%s+[%w_]+:" .. method_name .. "%s*%(.*%)"
    local _, line_count = string.gsub(string.sub(file_content, 1, string.find(file_content, pattern) or 0), "\n", "\n")

    return line_count + 1 -- Add 1 because line count starts at 0
end

-- Find all test files in the test directory
function runner.find_test_files()
    local test_files = {}
    local items = love.filesystem.getDirectoryItems("test")

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
    local test_path = "test." .. file_name:gsub("%.lua$", "")

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
function runner.run_test_method(test_class, method_name, method, results, file_path, line_number)
    results.tests_run = results.tests_run + 1

    -- Print the test case with indentation and source location
    local location_info = ""
    if file_path and line_number then
        location_info = " (" .. file_path .. ":" .. line_number .. ")"
    end

    log.info("> " .. test_class._NAME .. "." .. method_name .. location_info)

    -- Set the current test name so setUp and tearDown know which test is running
    test_class._currentTestName = method_name

    -- Call setUp if it exists
    if type(test_class.setUp) == "function" then
        log.debug("SETUP: " .. test_class._NAME .. "." .. method_name)
        local setup_success, setup_err = pcall(test_class.setUp, test_class)
        if not setup_success then
            results.failures = results.failures + 1
            log.error("FAIL: " .. test_class._NAME .. "." .. method_name .. " (setUp failed)")
            log.error("  " .. tostring(setup_err))
            return false
        end
    end

    -- Call the test method
    local success, err = pcall(method, test_class)

    -- Call tearDown if it exists (even if the test failed)
    if type(test_class.tearDown) == "function" then
        log.debug("TEARDOWN: " .. test_class._NAME .. "." .. method_name)
        local teardown_success, teardown_err = pcall(test_class.tearDown, test_class)
        if not teardown_success then
            log.error("FAIL: " .. test_class._NAME .. "." .. method_name .. " (tearDown failed)")
            log.error("  " .. tostring(teardown_err))
            -- Don't count a tearDown failure as a test failure if the test itself passed
            if success then
                results.failures = results.failures + 1
                success = false
            end
        end
    end

    -- Reset the current test name
    test_class._currentTestName = nil

    -- Record test result
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
    
    -- Track which test classes have been executed
    local executed_classes = {}
    
    -- Track which test methods have been executed (to prevent duplicates)
    local executed_methods = {}

    -- Find and run all test classes
    for class_name, class_obj in pairs(_G) do
        if type(class_obj) == "table" and class_name:match("^Test") and not executed_classes[class_name] then
            -- Store the class name for better error reporting
            class_obj._NAME = class_name
            
            -- Get the file name for this test class
            local file_name = test_class_to_file[class_name]

            -- Create full file path
            local full_file_path = "test/" .. file_name

            -- Load file content to find line numbers
            local file_content = runner.get_file_content(full_file_path)

            -- Log the file name if we haven't executed it yet
            if file_name and not executed_files[file_name] then
                log.info("Running tests from: " .. full_file_path)
                executed_files[file_name] = true
                results.current_file = file_name
            end
            
            -- Run all test methods in this class
            for method_name, method in pairs(class_obj) do
                -- Generate a unique key for this test method
                local method_key = class_name .. "." .. method_name
                
                if type(method) == "function" and method_name:match("^test") and not executed_methods[method_key] then
                    local line_number = nil
                    if file_content then
                        line_number = runner.find_method_line_number(file_content, method_name)
                    end
                    runner.run_test_method(class_obj, method_name, method, results, full_file_path, line_number)
                    
                    -- Mark this test as run to prevent duplicates
                    executed_methods[method_key] = true
                end
            end
            
            executed_classes[class_name] = true
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