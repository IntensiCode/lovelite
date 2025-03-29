-- ANSI color codes for terminal output
local ansi = {
    -- Reset (universal support)
    RESET = "\27[0m",

    -- Basic foreground colors (very widely supported)
    BLACK = "\27[30m",
    RED = "\27[31m",
    GREEN = "\27[32m",
    YELLOW = "\27[33m",
    BLUE = "\27[34m",
    MAGENTA = "\27[35m",
    CYAN = "\27[36m",
    WHITE = "\27[37m",

    -- Basic background colors (widely supported)
    BG_BLACK = "\27[40m",
    BG_RED = "\27[41m",
    BG_GREEN = "\27[42m",
    BG_YELLOW = "\27[43m",
    BG_BLUE = "\27[44m",
    BG_MAGENTA = "\27[45m",
    BG_CYAN = "\27[46m",
    BG_WHITE = "\27[47m",

    -- Common text styles (mostly well-supported)
    BOLD = "\27[1m",
    UNDERLINE = "\27[4m",
    REVERSE = "\27[7m", -- Inverts foreground and background

    -- Common aliases
    ORANGE = "\27[33m", -- Same as YELLOW
    GRAY = "\27[90m"    -- Bright black
}

-- Utility functions
-- Define these as methods of the ansi table

-- Utility function to check if the terminal supports colors
function ansi.supports_colors()
    -- Most LÖVE console outputs and terminals support colors
    -- You could add additional checks here for specific platforms if needed
    return true
end

-- Utility to enable all color codes
function ansi.enable()
    for k, v in pairs(ansi) do
        if type(v) == "string" then
            _G["ANSI_" .. k] = v
        end
    end
end

-- Utility to wrap text with color codes
function ansi.colorize(text, color_code)
    return color_code .. text .. ansi.RESET
end

return ansi
