require("src.base.log")
require("src.base.string")
require("src.base.table")
require("src.libraries.luaunit")

-- Test runner module
local runner = {}

-- Helper function for filtered stack traces
function runner.filtered_xpcall(fn)
    local function filter_traceback(err)
        local trace = debug.traceback(err)
        local filtered = {}
        for line in trace:gmatch("[^\n]+") do
            if not line:match("%[C%]") and not line:match("%[love") then
                table.insert(filtered, line)
            end
        end
        return table.concat(filtered, "\n")
    end
    return xpcall(fn, filter_traceback)
end

-- Initialize data storage in runner
runner.specific_tests = {}
runner.test_files = {}
runner.test_class_to_file = {} -- Map of test class names to their source files

-- Initialize results fields
runner.tests_executed = 0
runner.failures = 0
runner.errors = 0
runner.passed = 0
runner.current_file = nil
runner.last_error = nil

-- Reset the test results
function runner.reset_results()
    runner.tests_executed = 0
    runner.failures = 0
    runner.errors = 0
    runner.passed = 0
    runner.current_file = nil
    runner.last_error = nil
end

function runner._accept_test_file(file_name)
    if #runner.test_files == 0 then
        return true
    end

    -- Check if any requested test file is a substring of this file_name
    for _, test_file in ipairs(runner.test_files) do
        if file_name:find(test_file, 1, true) then
            return true
        end
    end

    return false
end

-- Get success status based on test results
function runner.success()
    return runner.failures == 0 and runner.errors == 0
end

function runner._accept_test_function(file_name, method_name)
    local file_base = file_name:gsub("%.lua$", "")
    local specific_tests = runner.specific_tests[file_base] or {}
    if not next(specific_tests) then
        return true
    end
    return table.contains(specific_tests, method_name)
end

--- Parse and normalize test option argument
function runner.parse_test_option(test_arg)
    -- Handle table from argparse
    if type(test_arg) == "table" and #test_arg == 1 then
        test_arg = test_arg[1]
    end

    -- Run all tests if no specific files requested
    if test_arg == true then
        return
    end

    -- Process string with file names
    if type(test_arg) == "string" then
        runner.parse_file_list(test_arg)
    end
end

function runner.ensure_specific_tests(file_name)
    if not runner.specific_tests then
        runner.specific_tests = {}
    end
    if not runner.specific_tests[file_name] then
        runner.specific_tests[file_name] = {}
    end
end

--- Split the comma-separated list of files
--- Split into file and function if : is present
---@param file_list string The comma-separated list of files to parse
function runner.parse_file_list(file_list)
    for file in string.gmatch(file_list, "([^,]+)") do
        -- If : in file, split into file and function:
        local _file, _func = file:match("^([^:]+):([^:]+)$")
        if _file and _func then
            runner.ensure_specific_tests(_file)
            table.insert(runner.test_files, _file)
            table.insert(runner.specific_tests[_file], _func)
        else
            table.insert(runner.test_files, file)
        end
    end

    log.debug("Test files: " .. table.concat(runner.test_files, ", "))
    if next(runner.specific_tests) then
        local which = table.concat_deep(runner.specific_tests, ", ")
        log.debug("Specific tests: " .. which)
    end
end

-- Get file content to find line numbers for test methods
function runner.get_file_content(file_path)
    local content = nil
    if love.filesystem.getInfo(file_path) then
        content = love.filesystem.read(file_path)
    end
    return content
end

-- Find line number for a method in a file content
function runner.find_method_line_number(file_content, method_name)
    if not file_content then
        return nil
    end

    -- Look for "function test_xxx:method_name" or similar patterns
    local pattern = "function%s+[%w_]+:" .. method_name .. "%s*%(.*%)"
    local pos = string.find(file_content, pattern)
    if not pos then
        return 0
    end

    -- Count newlines up to the match position
    local _, line_count = string.gsub(string.sub(file_content, 1, pos), "\n", "\n")
    return line_count + 1 -- Add 1 because line count starts at 0
end

-- Helper function to recursively find test files
local function find_test_files_recursive(base_path, files)
    local items = love.filesystem.getDirectoryItems(base_path)

    for _, item in ipairs(items) do
        local full_path = base_path .. "/" .. item
        local info = love.filesystem.getInfo(full_path)

        if info.type == "directory" then
            -- Recursively search subdirectory
            find_test_files_recursive(full_path, files)
        elseif info.type == "file" then
            -- Only include Lua files that start with "test_"
            local is_test = item:match("^test_.+%.lua$")
            if is_test then
                -- Store relative path from test directory
                local rel_path = full_path:gsub("^test/", "")
                if runner._accept_test_file(rel_path) then
                    table.insert(files, rel_path)
                end
            end
        end
    end
end

-- Get all test files from the test directory and subdirectories
function runner.find_all_test_files()
    local test_files = {}
    find_test_files_recursive("test", test_files)
    return test_files
end

-- Load a test file and map its test classes to the file
function runner.load_test_file(file_name)
    -- Convert file path to module path for require
    local test_path = "test." .. file_name:gsub("%.lua$", ""):gsub("/", ".")

    -- Record test classes before loading
    local before_classes = runner.get_existing_test_classes()

    -- Require the test file
    require(test_path)

    -- Find and map new test classes
    runner.map_new_test_classes(before_classes, file_name)
end

-- Find new test classes added after loading a file
function runner.map_new_test_classes(before_classes, file_name)
    local new_classes = {}

    for k, v in pairs(_G) do
        -- Check if this is a new test class (using snake_case naming convention)
        if type(v) == "table" and k:match("^test_") and not before_classes[k] then
            runner.test_class_to_file[k] = file_name
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
        runner.load_test_file(file_name)
        log.debug("Loaded test file: " .. file_name)
    end

    log.debug("Total test files loaded: " .. #test_files)
    return test_files, test_class_to_file
end

-- Run a single test method
function runner.run_test_method(
    test_class,
    method_name,
    method,
    file_path,
    line_number
)
    runner.tests_executed = runner.tests_executed + 1

    runner.log_test_start(test_class, method_name, file_path, line_number)

    test_class._current_test_name = method_name
    test_class._current_line_number = line_number

    local _success = runner.run_test_with_lifecycle(test_class, method_name, method)

    test_class._current_test_name = nil
    test_class._current_line_number = nil

    runner.record_test_result(_success, test_class, method_name)

    return _success
end

-- Log the start of a test
function runner.log_test_start(test_class, method_name, file_path, line_number)
    local where = runner.format_test_location(test_class, method_name)
    log.info("> " .. where)
end

-- Run a test with its setup and teardown methods
function runner.run_test_with_lifecycle(test_class, method_name, method)
    -- Run setup if it exists
    if not runner.run_setup(test_class, method_name) then
        return false
    end

    -- Call the test method
    local _success, err = runner.filtered_xpcall(function()
        method(test_class)
    end)

    -- Run teardown - may affect success status if it fails
    local teardown_success = runner.run_teardown(test_class, method_name)

    -- Only consider the test successful if both the test and teardown succeeded
    if not teardown_success and _success then
        _success = false
    end

    -- Store error for reporting
    if not _success then
        runner.last_error = err
    end

    return _success
end

-- Run the setup method for a test
function runner.run_setup(test_class, method_name)
    if type(test_class.setup) ~= "function" then
        return true
    end

    local where = runner.format_test_location(test_class, method_name)
    log.debug("SETUP: " .. where)
    local setup_success, setup_err = runner.filtered_xpcall(function()
        test_class.setup(test_class)
    end)

    if not setup_success then
        runner.failures = runner.failures + 1
        log.error("FAIL: " .. where .. " (setup failed)")
        log.error("  " .. tostring(setup_err))
        return false
    end

    return true
end

-- Run the teardown method for a test
function runner.run_teardown(test_class, method_name)
    if type(test_class.teardown) ~= "function" then
        return true
    end

    local where = runner.format_test_location(test_class, method_name)
    log.debug("TEARDOWN: " .. where)
    local teardown_success, teardown_err = runner.filtered_xpcall(function()
        test_class.teardown(test_class)
    end)

    if not teardown_success then
        log.error("FAIL: " .. where .. " (teardown failed)")
        log.error("  " .. tostring(teardown_err))
        runner.failures = runner.failures + 1
        return false
    end

    return true
end

-- Format a test location string in the format: test/path/to/file.lua:line:method_name
function runner.format_test_location(test_class, method_name)
    local file_path = runner.test_class_to_file[test_class._NAME]
    if not test_class._line_numbers then
        test_class._line_numbers = {}
    end
    local line_number = test_class._line_numbers[method_name] or 0
    return file_path .. ":" .. line_number .. ":" .. method_name
end

-- Record test result in results
function runner.record_test_result(success, test_class, method_name)
    local where = runner.format_test_location(test_class, method_name)
    if success then
        runner.passed = runner.passed + 1
        log.debug("PASS: " .. where)
    else
        runner.failures = runner.failures + 1
        log.error("FAIL: " .. where)
        log.error("  " .. tostring(runner.last_error))
    end
end

-- Execute all test classes and methods
function runner.execute_tests()
    -- Reset results
    runner.reset_results()

    -- Tracking structures
    local executed_files = {}
    local executed_classes = {}
    local executed_methods = {}

    -- Run tests for all test classes in global scope
    for class_name, class_obj in pairs(_G) do
        if runner.is_test_class(class_name, class_obj, executed_classes) then
            -- Get file info
            local file_name = runner.test_class_to_file[class_name]
            class_obj._NAME = class_name -- Store name for better reporting

            runner.log_file_header(file_name, executed_files)
            runner.run_test_methods(class_obj, file_name, executed_methods)

            executed_classes[class_name] = true
        end
    end
end

-- Create a new test results structure
function runner.create_results()
    return {
        tests_run = 0,
        failures = 0,
        errors = 0,
        passed = 0,
        current_file = nil,
        last_error = nil,
    }
end

-- Check if an object is a test class that hasn't been executed yet
function runner.is_test_class(class_name, class_obj, executed_classes)
    return type(class_obj) == "table"
        and class_name:match("^test_")
        and not executed_classes[class_name]
end

-- Log the file header for a new test file
function runner.log_file_header(file_name, executed_files)
    if not file_name or executed_files[file_name] then
        return
    end

    local full_file_path = "test/" .. file_name
    log.debug("Running tests from: " .. full_file_path)
    executed_files[file_name] = true
    runner.current_file = file_name
end

-- Helper function to identify test methods in a class
function runner.identify_test_methods(class_obj, file_content, executed_methods)
    local identified_methods = {}
    for method_name, method in pairs(class_obj) do
        local is_test = runner.is_test_method(
            class_obj._NAME,
            method_name,
            method,
            executed_methods
        )
        if is_test then
            local line_number =
                runner.find_method_line_number(file_content, method_name)
            table.insert(identified_methods, {
                name = method_name,
                method = method,
                line_number = line_number,
            })
        end
    end
    return identified_methods
end

-- Run all test methods in a test class
function runner.run_test_methods(class_obj, file_name, executed_methods)
    -- Get file content for line numbers
    local full_file_path = "test/" .. file_name
    local file_content = runner.get_file_content(full_file_path)

    -- 1. Identify all test methods first
    local methods_to_run =
        runner.identify_test_methods(class_obj, file_content, executed_methods)

    -- 2. Filter methods to run
    methods_to_run = table.filter(methods_to_run, function(m)
        return runner._accept_test_function(file_name, m.name)
    end)

    -- 3. Log identified methods
    local method_names = table.map(methods_to_run, function(m)
        return runner.format_test_location(class_obj, m.name)
    end)
    if #method_names > 0 then
        log.debug(
            "  Identified test methods for "
                .. class_obj._NAME
                .. ": "
                .. table.concat(method_names, ", ")
        )
    else
        log.error("  No test methods identified for " .. class_obj._NAME)
    end

    -- Store line numbers in the class for each method
    class_obj._line_numbers = {}
    for _, test_info in ipairs(methods_to_run) do
        class_obj._line_numbers[test_info.name] = test_info.line_number
    end

    -- 4. Execute identified methods
    for _, test_info in ipairs(methods_to_run) do
        -- Run the test
        runner.run_test_method(
            class_obj,
            test_info.name,
            test_info.method,
            full_file_path,
            test_info.line_number
        )

        -- Mark as executed
        executed_methods[class_obj._NAME .. "." .. test_info.name] = true
    end
end

-- Check if a method is a test method that hasn't been executed
function runner.is_test_method(class_name, method_name, method, executed_methods)
    local method_key = class_name .. "." .. method_name

    return type(method) == "function"
        and method_name:match("^test")
        and not executed_methods[method_key]
end

-- Main entry point: run all test files and return success status
function runner.run()
    log.debug("Running test suite")

    -- Find test files to run
    local test_files = runner.find_all_test_files()

    -- Load all test classes from the files
    runner.load_test_classes(test_files)

    -- Log the discovered test classes
    local class_names = {}
    for name, _ in pairs(runner.test_class_to_file) do
        table.insert(class_names, name)
    end
    local which = #class_names > 0 and table.concat(class_names, ", ") or "None"
    log.debug("Discovered test classes: " .. which)

    -- Execute tests and print summary
    runner.execute_tests()
    return runner.print_summary()
end

-- Load all test classes from the specified files
function runner.load_test_classes(test_files)
    -- Clear existing mappings
    runner.test_class_to_file = {}

    -- Load each test file
    for _, file in ipairs(test_files) do
        runner.load_test_file(file)
        log.debug("Loaded test file: " .. file)
    end

    log.debug("Total test files loaded: " .. #test_files)
    return runner.test_class_to_file
end

-- Get a map of existing test classes before loading files
function runner.get_existing_test_classes()
    local existing_classes = {}

    for k, v in pairs(_G) do
        if type(v) == "table" and k:match("^test_") then
            existing_classes[k] = true
        end
    end

    return existing_classes
end

-- Print test summary (log.info)
function runner.print_summary()
    local summary = string.format(
        "Test Summary: %d tests, %d passed, %d failures, %d errors",
        runner.tests_executed,
        runner.passed,
        runner.failures,
        runner.errors
    )
    local result = runner.success()
    log.info("-------------------------------------")
    log.info(summary)
    if result then
        log.info("ALL TESTS PASSED")
    else
        log.error("TEST SUITE FAILED")
    end
    log.info("-------------------------------------")
    return result
end

return runner
