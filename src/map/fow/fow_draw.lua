-- FOW Draw Module
-- Handles rendering and visualization of the fog of war effect.
-- Creates and updates the canvas used to draw dithered fog patterns.
-- Draws different levels of fog density based on visibility values.
-- Provides efficient rendering by only updating when visibility changes.

local fow_dither = require("src.map.fow.fow_dither")
local fow_config = require("src.map.fow.fow_config")

local fow_draw = {}

---Update the fog of war canvas based on the current grid state
---@param fog_of_war table The main fog of war module
function fow_draw.update_canvas(fog_of_war)
    if not fow_config.canvas or not fow_config.canvas_dirty then return end

    love.graphics.setCanvas(fow_config.canvas)
    love.graphics.clear(0, 0, 0, 0) -- Start with completely transparent

    -- Scale factor to match the tile size with the dither size
    local dither_scale = fow_config.tile_size / fow_dither.DITHER_SIZE

    -- Draw fog patterns for each tile according to its visibility level
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            local fog_level = 4 - fow_config.grid[y][x] -- Convert from our grid value to dither level
            
            -- Only draw if not fully transparent (fog_level > 0)
            if fog_level > 0 then
                -- Draw the dither pattern at this position
                fow_dither.draw_pattern(
                    fog_level,
                    (x - 1) * fow_config.tile_size,
                    (y - 1) * fow_config.tile_size,
                    dither_scale
                )
            end
        end
    end

    -- Reset graphics state
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)

    -- Mark the canvas as no longer dirty
    fow_config.canvas_dirty = false
end

---Draw the fog of war on screen
---@param fog_of_war table The main fog of war module
function fow_draw.draw(fog_of_war)
    if not fow_config.enabled or not fow_config.canvas then return end

    -- Save current graphics state
    local r, g, b, a = love.graphics.getColor()

    -- Draw the fog canvas with multiply blend mode
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(fow_config.canvas, 0, 0)

    -- Restore previous graphics state
    love.graphics.setColor(r, g, b, a)
end

return fow_draw
