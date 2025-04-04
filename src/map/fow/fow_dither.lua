-- FOW Dither Module
-- Creates and manages dithering patterns used to visualize different fog densities.
-- Generates a sprite sheet with various dither patterns for efficient rendering.
-- Provides patterns for light, medium, and heavy fog as well as fully obscured areas.
-- Handles drawing dither patterns at specified positions with appropriate scaling.

local fow_config = require("src.map.fow.fow_config")
local levels = require("src.map.fow.fow_levels")

local fow_dither = {}

-- Constants
fow_dither.DITHER_SIZE = 16
fow_dither.PATTERN_SIZE = 4
fow_dither.LEVELS = 5

-- Define all dithering patterns at the top of the file
local DITHER_PATTERNS = {
    -- Level 0: Fully hidden - solid black
    [levels.HIDDEN_0] = {
        { 1, 1, 1, 1 },
        { 1, 1, 1, 1 },
        { 1, 1, 1, 1 },
        { 1, 1, 1, 1 },
    },

    -- Level 1: Heavy fog - 75% dithering
    [levels.HEAVY_FOG_1] = {
        { 0, 1, 0, 1 },
        { 1, 1, 1, 1 },
        { 0, 1, 0, 1 },
        { 1, 1, 1, 1 },
    },

    -- Level 2: Medium fog - 50% dithering (checkerboard pattern)
    [levels.MEDIUM_FOG_2] = {
        { 0, 1, 0, 1 },
        { 1, 0, 1, 0 },
        { 0, 1, 0, 1 },
        { 1, 0, 1, 0 },
    },

    -- Level 3: Light fog - 25% dithering
    [levels.LIGHT_FOG_3] = {
        { 0, 0, 0, 0 },
        { 0, 1, 0, 1 },
        { 0, 0, 0, 0 },
        { 0, 1, 0, 1 },
    },

    -- Level 4: Fully visible - completely transparent
    [levels.VISIBLE_4] = {},
}

-- The sprite sheet containing all dither patterns
fow_dither.sprite_sheet = nil
fow_dither.quads = {}

---Draw a dither pattern at the specified position
---@param x number The x position
---@param y number The y position
---@param visibility number The fog level (0=hidden to 4=visible)
function fow_dither.draw(x, y, visibility)
    -- Skip drawing for fully visible tiles
    if visibility == levels.VISIBLE_4 then
        return
    end
    local quad = fow_dither.quads[visibility]
    love.graphics.draw(
        fow_dither.sprite_sheet,
        quad,
        (x - 1) * fow_config.tile_size,
        (y - 1) * fow_config.tile_size
    )
end

---Generate the dithering patterns and create a sprite sheet
function fow_dither.create_sprite_sheet()
    -- Create a new canvas to draw the patterns
    local dither_size = fow_dither.DITHER_SIZE
    local pattern_size = fow_dither.PATTERN_SIZE
    local canvas =
        love.graphics.newCanvas(dither_size * fow_dither.LEVELS, dither_size)

    -- Set up the canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0) -- Start with transparent background

    -- Draw each dither pattern onto the canvas
    for level = 0, fow_dither.LEVELS - 1 do
        log.debug("Drawing dither pattern for level %d", level)
        love.graphics.setColor(0, 0, 0, 1)

        -- Draw the pattern 4x4 times to fill the 16x16 area
        local pattern = DITHER_PATTERNS[level]
        for repeat_y = 0, 3 do
            for repeat_x = 0, 3 do
                for y = 1, pattern_size do
                    for x = 1, pattern_size do
                        if pattern[y] and pattern[y][x] == 1 then
                            love.graphics.rectangle(
                                "fill",
                                level * dither_size
                                    + (repeat_x * pattern_size)
                                    + x
                                    - 1,
                                (repeat_y * pattern_size) + y - 1,
                                1,
                                1
                            )
                        end
                    end
                end
            end
        end
    end

    -- Reset graphics state
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)

    -- Save the sprite sheet
    fow_dither.sprite_sheet = canvas

    -- Create quads for each pattern
    for i = 0, fow_dither.LEVELS - 1 do
        fow_dither.quads[i] = love.graphics.newQuad(
            i * dither_size,
            0,
            dither_size,
            dither_size,
            canvas:getDimensions()
        )
    end

    return fow_dither.sprite_sheet
end

---Draw a dither pattern at the specified position
---@param level number The fog level (0-4)
---@param x number The x position
---@param y number The y position
---@param scale number Optional scale factor (default: 1)
function fow_dither.draw_pattern(level, x, y, scale)
    scale = scale or 1

    -- Ensure the sprite sheet exists
    if not fow_dither.sprite_sheet then
        fow_dither.create_sprite_sheet()
    end

    -- Ensure level is valid
    level = math.max(0, math.min(fow_dither.LEVELS - 1, level))

    -- Skip drawing for level 0 (fully visible)
    if level == 0 then
        return
    end

    -- Draw the dither pattern
    love.graphics.draw(
        fow_dither.sprite_sheet,
        fow_dither.quads[level],
        x,
        y,
        0, -- rotation
        scale,
        scale -- scale x, y
    )
end

return fow_dither
