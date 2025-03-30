require("src.libraries.luaunit")
require("src.base.log")

-- Test runner module
local runner = {}

-- Parse and normalize test option argument
function runner.parse_test_option(test_arg)
    -- Handle table from argparse
    if type(test_arg) == "table" and #test_arg == 1 then
        test_arg = test_arg[1]
    end

    -- Run all tests if no specific files requested
    if test_arg == true then
        return {}
    end

    -- Process string with file names
    if type(test_arg) == "string" then
        return runner.parse_file_list(test_arg)
    end

    -- Default to all tests
    return {}
end

-- Split a comma-separated list of files
function runner.parse_file_list(file_list)
    local files = {}

    for file in string.gmatch(file_list, "([^,]+)") do
        local trimmed = file:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
        table.insert(files, trimmed)
    end

    -- Fail if specific files contains "test/" or ".lua" or ":..."
    for _, file in ipairs(files) do
        if file:match("test/") or file:match("%.lua$") or file:match(":%d+") then
            return nil
        end
    end


    return files
end

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
function runner.find_test_files(specific_files)
    -- If specific files were requested, use only those
    if specific_files and #specific_files > 0 then
        local files = runner.normalize_test_files(specific_files)
        if #files > 0 then
            return files
        end

        log.warn("No valid test files found from specified list, running all tests instead")
    end

    -- If no specific files were requested or none were found, get all test files
    return runner.get_all_test_files()
end

-- Validate and normalize test file paths
function runner.normalize_test_files(file_list)
    local test_files = {}

    for _, file_name in ipairs(file_list) do
        local file = runner.normalize_test_file_name(file_name)

        -- Check if the file exists
        if love.filesystem.getInfo("test/" .. file) then
            table.insert(test_files, file)
            log.info("Adding specific test file: " .. file)
        else
            log.warn("Requested test file not found: " .. file)
        end
    end

    return test_files
end

-- Normalize a single test file name
function runner.normalize_test_file_name(file_name)
    local file = file_name

    -- Add .lua extension if not present
    if not file:match("%.lua$") then
        file = file .. ".lua"
    end

    -- Add test_ prefix if not present
    if not file:match("^test_") then
        file = "test_" .. file
    end

    return file
end

-- Get all test files from the test directory
function runner.get_all_test_files()
    local test_files = {}
    local items = love.filesystem.getDirectoryItems("test")

    for _, item in ipairs(items) do
        -- Only include Lua files that start with "test_" or end with "_test"
        local is_test = item:match("^test_.+%.lua$") or item:match("^.+_test%.lua$")
        local not_runner = item ~= "run_tests.lua" and item ~= "run_tests_love.lua"

        if is_test and not_runner then
            table.insert(test_files, item)
        end
    end

    return test_files
end

-- Load a test file and map its test classes to the file
function runner.load_test_file(file_name, test_class_to_file)
    -- Get the module path for require
    local test_path = "test." .. file_name:gsub("%.lua$", "")

    -- Record test classes before loading
    local before_classes = runner.get_existing_test_classes()

    -- Require the test file
    require(test_path)

    -- Find and map new test classes
    runner.map_new_test_classes(before_classes, file_name, test_class_to_file)
end

-- Find new test classes added after loading a file
function runner.map_new_test_classes(before_classes, file_name, test_class_to_file)
    local new_classes = {}

    for k, v in pairs(_G) do
        -- Check if this is a new test class
        if type(v) == "table" and k:match("^Test") and not before_classes[k] then
            test_class_to_file[k] = file_name
            table.insert(new_classes, k)
            log.debug("Found test class " .. k .. " in file " .. file_name)
        end
    end

    return new_classes
end

-- Load all test files and build class-to-file mapping
function runner.load_test_files(specific_files)
    local test_files = runner.find_test_files(specific_files)
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

    -- Print test information
    runner.log_test_start(test_class, method_name, file_path, line_number)

    -- Set the current test name so setUp and tearDown know which test is running
    test_class._currentTestName = method_name

    -- Run the test with setup and teardown
    local success = runner.run_test_with_lifecycle(test_class, method_name, method, results)

    -- Reset the current test name
    test_class._currentTestName = nil

    -- Record test result
    runner.record_test_result(success, test_class, method_name, results)

    return success
end

-- Log the start of a test
function runner.log_test_start(test_class, method_name, file_path, line_number)
    local location_info = ""
    if file_path and line_number then
        location_info = " (" .. file_path .. ":" .. line_number .. ")"
    end

    log.info("> " .. test_class._NAME .. "." .. method_name .. location_info)
end

-- Run a test with its setup and teardown methods
function runner.run_test_with_lifecycle(test_class, method_name, method, results)
    -- Run setUp if it exists
    if not runner.run_setup(test_class, method_name, results) then
        return false
    end

    -- Call the test method
    local success, err = pcall(method, test_class)

    -- Run tearDown - may affect success status if it fails
    local teardown_success = runner.run_teardown(test_class, method_name, results)

    -- Only consider the test successful if both the test and teardown succeeded
    if not teardown_success and success then
        success = false
    end

    -- Store error for reporting
    if not success then
        results.last_error = err
    end

    return success
end

-- Run the setUp method for a test
function runner.run_setup(test_class, method_name, results)
    if type(test_class.setUp) ~= "function" then
        return true
    end

    log.debug("SETUP: " .. test_class._NAME .. "." .. method_name)
    local setup_success, setup_err = pcall(test_class.setUp, test_class)

    if not setup_success then
        results.failures = results.failures + 1
        log.error("FAIL: " .. test_class._NAME .. "." .. method_name .. " (setUp failed)")
        log.error("  " .. tostring(setup_err))
        return false
    end

    return true
end

-- Run the tearDown method for a test
function runner.run_teardown(test_class, method_name, results)
    if type(test_class.tearDown) ~= "function" then
        return true
    end

    log.debug("TEARDOWN: " .. test_class._NAME .. "." .. method_name)
    local teardown_success, teardown_err = pcall(test_class.tearDown, test_class)

    if not teardown_success then
        log.error("FAIL: " .. test_class._NAME .. "." .. method_name .. " (tearDown failed)")
        log.error("  " .. tostring(teardown_err))
        results.failures = results.failures + 1
        return false
    end

    return true
end

-- Record test result in results
function runner.record_test_result(success, test_class, method_name, results)
    if success then
        results.passed = results.passed + 1
        log.debug("PASS: " .. test_class._NAME .. "." .. method_name)
    else
        results.failures = results.failures + 1
        log.error("FAIL: " .. test_class._NAME .. "." .. method_name)
        log.error("  " .. tostring(results.last_error))
    end
end

-- Execute all test classes and methods
function runner.execute_tests(test_class_to_file)
    -- Test results storage
    local results = runner.create_results()

    -- Tracking structures
    local executed_files = {}
    local executed_classes = {}
    local executed_methods = {}

    -- Run tests for all test classes in global scope
    for class_name, class_obj in pairs(_G) do
        if runner.is_test_class(class_name, class_obj, executed_classes) then
            -- Get file info
            local file_name = test_class_to_file[class_name]
            class_obj._NAME = class_name -- Store name for better reporting

            -- Log file header if first test in file
            runner.maybe_log_file_header(file_name, executed_files, results)

            -- Run all test methods in this class
            runner.run_test_methods(class_obj, file_name, executed_methods, results)

            executed_classes[class_name] = true
        end
    end

    return results
end

-- Create a new test results structure
function runner.create_results()
    return {
        tests_run = 0,
        failures = 0,
        errors = 0,
        passed = 0,
        current_file = nil,
        last_error = nil
    }
end

-- Check if an object is a test class that hasn't been executed yet
function runner.is_test_class(class_name, class_obj, executed_classes)
    return type(class_obj) == "table" and
        class_name:match("^Test") and
        not executed_classes[class_name]
end

-- Log the file header for a new test file
function runner.maybe_log_file_header(file_name, executed_files, results)
    if not file_name or executed_files[file_name] then
        return
    end

    local full_file_path = "test/" .. file_name
    log.info("Running tests from: " .. full_file_path)
    executed_files[file_name] = true
    results.current_file = file_name
end

-- Helper function to identify test methods in a class
function runner.identify_test_methods(class_obj, file_content, executed_methods)
    local identified_methods = {}
    for method_name, method in pairs(class_obj) do
        if runner.is_test_method(class_obj._NAME, method_name, method, executed_methods) then
            local line_number = runner.find_method_line_number(file_content, method_name)
            table.insert(identified_methods, {
                name = method_name,
                method = method,
                line_number = line_number
            })
        end
    end
    return identified_methods
end

-- Run all test methods in a test class
function runner.run_test_methods(class_obj, file_name, executed_methods, results)
    -- Get file content for line numbers
    local full_file_path = "test/" .. file_name
    local file_content = runner.get_file_content(full_file_path)

    -- 1. Identify all test methods first
    local methods_to_run = runner.identify_test_methods(class_obj, file_content, executed_methods)

    -- 2. Log identified methods
    local method_names = {}
    for _, m in ipairs(methods_to_run) do
        table.insert(method_names, class_obj._NAME .. "." .. m.name)
    end

    if #method_names > 0 then
        log.info("  Identified test methods for " .. class_obj._NAME .. ": " .. table.concat(method_names, ", "))
    else
        log.error("  No test methods identified for " .. class_obj._NAME)
        return -- No methods to run
    end

    -- 3. Execute identified methods
    for _, test_info in ipairs(methods_to_run) do
        -- Run the test
        runner.run_test_method(class_obj, test_info.name, test_info.method, results, full_file_path,
            test_info.line_number)

        -- Mark as executed
        executed_methods[class_obj._NAME .. "." .. test_info.name] = true
    end
end

-- Check if a method is a test method that hasn't been executed
function runner.is_test_method(class_name, method_name, method, executed_methods)
    local method_key = class_name .. "." .. method_name

    return type(method) == "function" and
        method_name:match("^test") and
        not executed_methods[method_key]
end

-- Main entry point: run all test files and return success status
function runner.run(specific_files)
    log.info("Starting test suite...")

    -- Load test files and map them to classes
    local test_files = runner.find_test_files(specific_files)
    runner.log_test_file_count(specific_files, test_files)

    -- Load all test classes from the files
    local test_class_to_file = runner.load_test_classes(test_files)

    -- Log the discovered test classes
    local class_names = {}
    for name, _ in pairs(test_class_to_file) do table.insert(class_names, name) end
    log.info("Discovered test classes: " .. (#class_names > 0 and table.concat(class_names, ", ") or "None"))

    -- Execute tests and print summary
    local results = runner.execute_tests(test_class_to_file)
    return runner.print_summary(results)
end

-- Log information about how many test files will be run
function runner.log_test_file_count(specific_files, test_files)
    if not specific_files or #specific_files == 0 then
        log.info("Running all test files")
    elseif #test_files > 0 then
        log.info("Running " .. #test_files .. " specific test files")
    else
        log.info("No valid test files found from specified list, running all tests instead")
    end
end

-- Load all test classes from the specified files
function runner.load_test_classes(test_files)
    local test_class_to_file = {}

    -- Get existing test classes for comparison
    local existing_test_classes = runner.get_existing_test_classes()

    -- Load each test file
    for _, file in ipairs(test_files) do
        runner.load_test_file(file, test_class_to_file)
        log.debug("Loaded test file: " .. file)
    end

    log.info("Total test files loaded: " .. #test_files)
    return test_class_to_file
end

-- Get a map of existing test classes before loading files
function runner.get_existing_test_classes()
    local existing_classes = {}

    for k, v in pairs(_G) do
        if type(v) == "table" and k:match("^Test") then
            existing_classes[k] = true
        end
    end

    return existing_classes
end

-- Print test summary
function runner.print_summary(results)
    log.info("-------------------------------------")
    runner.log_test_counts(results)

    local success = results.failures == 0 and results.errors == 0
    runner.log_success_status(success)

    log.info("-------------------------------------")
    return success
end

-- Log the test count summary
function runner.log_test_counts(results)
    local summary = string.format(
        "Test Summary: %d tests, %d passed, %d failures, %d errors",
        results.tests_run,
        results.passed,
        results.failures,
        results.errors
    )
    log.info(summary)
end

-- Log the overall test success status
function runner.log_success_status(success)
    if success then
        log.info("ALL TESTS PASSED")
    else
        log.error("TEST SUITE FAILED")
    end
end

-- Execute a specific test class.method
function runner.execute_specific_test(class_name, method_name)
    log.info("Executing specific test: " .. class_name .. "." .. method_name)

    -- Load all test files
    local _, test_class_to_file = runner.load_test_files()

    -- Validate test class and method
    if not runner.validate_specific_test(class_name, method_name) then
        return false
    end

    -- Run the specific test
    local test_class = _G[class_name]
    local test_file = test_class_to_file[class_name] or "unknown"

    log.info("Running test: " .. class_name .. "." .. method_name .. " (" .. test_file .. ")")

    -- Create simple results table
    local results = runner.create_simple_results()

    -- Run the test with lifecycle methods
    return runner.run_single_test(test_class, method_name, test_file, results)
end

-- Validate the test class and method exist
function runner.validate_specific_test(class_name, method_name)
    -- Check if the class exists
    if not _G[class_name] then
        log.error("Test class '" .. class_name .. "' not found")
        return false
    end

    -- Check if the method exists in the class
    if not _G[class_name][method_name] then
        log.error("Test method '" .. method_name .. "' not found in class '" .. class_name .. "'")
        return false
    end

    return true
end

-- Create a simple results table for a single test
function runner.create_simple_results()
    return {
        tests_executed = 0,
        tests_passed = 0,
        tests_failed = 0,
        tests_errors = 0,
        failures = {},
        errors = {}
    }
end

-- Run a single test with setup and teardown
function runner.run_single_test(test_class, method_name, test_file, results)
    -- Run setup if it exists
    if test_class.setUp then
        test_class:setUp()
    end

    -- Run the test method
    local success, err = xpcall(
        function() test_class[method_name](test_class) end,
        debug.traceback
    )

    -- Record results
    results.tests_executed = results.tests_executed + 1
    runner.record_single_test_result(success, err, test_class, method_name, test_file, results)

    -- Run teardown if it exists
    if test_class.tearDown then
        test_class:tearDown()
    end

    -- Print summary
    return runner.print_summary(results)
end

-- Record a single test result
function runner.record_single_test_result(success, err, test_class, method_name, test_file, results)
    if success then
        results.tests_passed = results.tests_passed + 1
        log.info("> " .. class_name .. "." .. method_name .. " (" .. test_file .. ")")
    else
        results.tests_failed = results.tests_failed + 1
        table.insert(results.failures, {
            class_name = test_class._NAME,
            method_name = method_name,
            error = err
        })
        log.error("FAIL: " .. test_class._NAME .. "." .. method_name)
        log.error(err)
    end
end

return runner
