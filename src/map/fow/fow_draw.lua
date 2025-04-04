-- FOW Draw Module
-- Handles rendering and visualization of the fog of war effect.
-- Creates and updates the canvas used to draw dithered fog patterns.
-- Draws different levels of fog density based on visibility values.
-- Provides efficient rendering by only updating when visibility changes.

local fow_config = require("src.map.fow.fow_config")
local fow_dither = require("src.map.fow.fow_dither")
local fow_memory = require("src.map.fow.fow_memory")

local fow_draw = {}

---Draw the fog of war
---@param translation_x number Camera translation X
---@param translation_y number Camera translation Y
function fow_draw.draw(translation_x, translation_y)
    if not fow_config.enabled then
        return
    end

    -- Store current blend mode
    local r, g, b, a = love.graphics.getColor()
    local saved1, saved2 = love.graphics.getBlendMode()

    -- Draw the fog canvas with multiply blend mode
    -- love.graphics.setBlendMode("multiply", "premultiplied")

    -- TODO transform to screen space / camera
    fow_memory.for_each_position(function(x, y, visibility)
        -- TODO skip outside screen / camera
        fow_dither.draw(x, y, visibility)
    end)

    -- Restore previous state
    love.graphics.setBlendMode(saved1, saved2)
    love.graphics.setColor(r, g, b, a)
end

return fow_draw
