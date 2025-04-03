-- Simple logging system
local ansi = require("src.base.ansi")

-- Log levels
local LOG_LEVELS = {
    OFF = 0,
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
}

-- Create log namespace
log = {
    dev = false,
    level = LOG_LEVELS.INFO, -- Default log level is INFO
    LEVELS = LOG_LEVELS,
    use_colors = ansi.supports_colors(),
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
    local formatted_message
    if select("#", ...) > 0 then
        local success, result = pcall(string.format, message, ...)
        if success then
            formatted_message = result
        else
            -- If formatting fails, concatenate arguments
            local args = { ... }
            for i = 1, #args do
                args[i] = tostring(args[i])
            end
            formatted_message = message .. " " .. table.concat(args, " ")
        end
    else
        formatted_message = message
    end

    -- Always log the assertion failure as an error
    log.error("Assertion failed: " .. formatted_message)

    -- Only throw an actual assertion in dev mode
    if log.dev then
        assert(false, formatted_message)
    end

    return condition
end

---Handle an error with traceback filtering and appropriate actions
---@param err any The error to handle
---@param context string Context description of where the error occurred
function log.handle_error(err, context)
    -- Get the traceback
    local traceback = debug.traceback(err)

    -- Filter out [C] frames but keep [love...] and others
    local filtered = {}
    for line in traceback:gmatch("[^\n]+") do
        if not line:match("%[C%]:") then
            table.insert(filtered, line)
        end
    end

    -- Log the filtered traceback
    log.error("Error in " .. context .. ":\n" .. table.concat(filtered, "\n"))

    -- If in dev mode and not in web, exit the game
    if log.dev then
        love.event.quit(1)
    end
end

return log
