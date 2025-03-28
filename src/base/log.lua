-- Simple logging system
local ansi = require("src.base.ansi")

-- Log levels
local LOG_LEVELS = {
    OFF = 0,
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4
}

-- Create log namespace
log = {
    dev = false,
    level = LOG_LEVELS.INFO, -- Default log level is INFO
    LEVELS = LOG_LEVELS,
    use_colors = ansi.supports_colors()
}

-- Helper function to format log messages
local function format_message(level, ...)
    local timestamp = os.date("%H:%M:%S")
    local args = { ... }
    local message = ""

    for i, v in ipairs(args) do
        message = message .. tostring(v)
        if i < #args then
            message = message .. " "
        end
    end

    return string.format("[%s] [%s] %s", timestamp, level, message)
end

-- Get color for log level
local function get_level_color(level)
    if not log.use_colors then
        return "", ""
    end

    if level == "ERROR" then
        return ansi.BOLD .. ansi.RED, ansi.RESET
    elseif level == "WARN" then
        return ansi.ORANGE, ansi.RESET
    elseif level == "INFO" then
        return ansi.GREEN, ansi.RESET
    elseif level == "DEBUG" then
        return ansi.GRAY, ansi.RESET
    else
        return "", ""
    end
end

-- Error level logging
function log.error(...)
    if log.level >= LOG_LEVELS.ERROR then
        local color_start, color_end = get_level_color("ERROR")
        print(color_start .. format_message("ERROR", ...) .. color_end)
    end
end

-- Warning level logging
function log.warn(...)
    if log.level >= LOG_LEVELS.WARN then
        local color_start, color_end = get_level_color("WARN")
        print(color_start .. format_message("WARN", ...) .. color_end)
    end
end

-- Info level logging
function log.info(...)
    if log.level >= LOG_LEVELS.INFO then
        local color_start, color_end = get_level_color("INFO")
        print(color_start .. format_message("INFO", ...) .. color_end)
    end
end

-- Debug level logging
function log.debug(...)
    if log.level >= LOG_LEVELS.DEBUG then
        local color_start, color_end = get_level_color("DEBUG")
        print(color_start .. format_message("DEBUG", ...) .. color_end)
    end
end

-- Set the log level
function log.set_level(level)
    if type(level) == "string" and LOG_LEVELS[level] then
        log.level = LOG_LEVELS[level]
    elseif type(level) == "number" then
        log.level = level
    else
        log.error("Invalid log level:", level)
    end
end

-- Enable or disable colors
function log.set_colors(enabled)
    log.use_colors = enabled and ansi.supports_colors()
end

-- Conditional assertion based on dev mode
function log.assert(condition, message, ...)
    if condition then
        return condition
    end

    -- Format the assert message with any additional arguments
    if select("#", ...) > 0 then
        message = string.format(message, ...)
    end

    -- Always log the assertion failure as an error
    log.error("Assertion failed: " .. message)

    -- Only throw an actual assertion in dev mode
    if log.dev then
        assert(false, message)
    end

    return condition
end

return log
