-- FOW Draw Module
-- Handles rendering and visualization of the fog of war effect.
-- Creates and updates the canvas used to draw dithered fog patterns.
-- Draws different levels of fog density based on visibility values.
-- Provides efficient rendering by only updating when visibility changes.

local fow_dither = require("src.map.fow.fow_dither")

local fow_draw = {}

---Update the fog of war canvas based on the current grid state
---@param fog_of_war table The main fog of war module
function fow_draw.update_canvas(fog_of_war)
    if not fog_of_war.canvas or not fog_of_war.canvas_dirty then return end

    love.graphics.setCanvas(fog_of_war.canvas)
    love.graphics.clear(0, 0, 0, 0) -- Start with completely transparent

    -- Scale factor to match the tile size with the dither size
    local dither_scale = fog_of_war.tile_size / fow_dither.DITHER_SIZE

    -- Draw fog patterns for each tile according to its visibility level
    for y = 1, fog_of_war.size.y do
        for x = 1, fog_of_war.size.x do
            local fog_level = 4 - fog_of_war.grid[y][x] -- Convert from our grid value to dither level
            
            -- Only draw if not fully transparent (fog_level > 0)
            if fog_level > 0 then
                -- Draw the dither pattern at this position
                fow_dither.draw_pattern(
                    fog_level,
                    (x - 1) * fog_of_war.tile_size,
                    (y - 1) * fog_of_war.tile_size,
                    dither_scale
                )
            end
        end
    end

    -- Reset graphics state
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)

    -- Mark the canvas as no longer dirty
    fog_of_war.canvas_dirty = false
end

---Draw the fog of war on screen
---@param fog_of_war table The main fog of war module
function fow_draw.draw(fog_of_war)
    if not fog_of_war.enabled or not fog_of_war.canvas then return end

    -- Save current graphics state
    local r, g, b, a = love.graphics.getColor()

    -- Draw the fog canvas with multiply blend mode
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(fog_of_war.canvas, 0, 0)

    -- Restore previous graphics state
    love.graphics.setColor(r, g, b, a)
end

return fow_draw
