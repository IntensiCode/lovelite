-- Simple logging system

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
    level = LOG_LEVELS.INFO, -- Default log level is INFO
    LEVELS = LOG_LEVELS
}

-- Helper function to format log messages
local function format_message(level, ...)
    local timestamp = os.date("%H:%M:%S")
    local args = {...}
    local message = ""
    
    for i, v in ipairs(args) do
        message = message .. tostring(v)
        if i < #args then
            message = message .. " "
        end
    end
    
    return string.format("[%s] [%s] %s", timestamp, level, message)
end

-- Error level logging
function log.error(...)
    if log.level >= LOG_LEVELS.ERROR then
        print(format_message("ERROR", ...))
    end
end

-- Warning level logging
function log.warn(...)
    if log.level >= LOG_LEVELS.WARN then
        print(format_message("WARN", ...))
    end
end

-- Info level logging
function log.info(...)
    if log.level >= LOG_LEVELS.INFO then
        print(format_message("INFO", ...))
    end
end

-- Debug level logging
function log.debug(...)
    if log.level >= LOG_LEVELS.DEBUG then
        print(format_message("DEBUG", ...))
    end
end

-- Set the log level
function log.set_level(level)
    if LOG_LEVELS[level] then
        log.level = LOG_LEVELS[level]
    else
        log.error("Invalid log level:", level)
    end
end

return log 