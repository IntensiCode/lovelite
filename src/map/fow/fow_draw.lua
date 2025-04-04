-- FOW Draw Module
-- Handles rendering and visualization of the fog of war effect.
-- Creates and updates the canvas used to draw dithered fog patterns.
-- Draws different levels of fog density based on visibility values.
-- Provides efficient rendering by only updating when visibility changes.

local fow_dither = require("src.map.fow.fow_dither")
local fow_config = require("src.map.fow.fow_config")

local fow_draw = {
    canvas = nil,
    canvas_dirty = true
}

---Initialize the fog of war canvas
---@param width number Width of the canvas in pixels
---@param height number Height of the canvas in pixels
function fow_draw.init_canvas(width, height)
    if love.graphics.isCreated then
        fow_draw.canvas = love.graphics.newCanvas(width, height)
    end
end

---Check if the canvas is initialized
---@return boolean is_initialized Whether the canvas exists
function fow_draw.has_canvas()
    return fow_draw.canvas ~= nil
end

---Mark the canvas as needing an update
function fow_draw.mark_dirty()
    fow_draw.canvas_dirty = true
end

---Update the fog of war canvas based on the current grid state
---@param fog_of_war table The main fog of war module
function fow_draw.update_canvas(fog_of_war)
    if not fow_draw.canvas or not fow_draw.canvas_dirty then return end

    -- Set up canvas for drawing
    love.graphics.setCanvas(fow_draw.canvas)
    love.graphics.clear()

    -- Draw fog dither patterns for each tile
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            local visibility = fow_config.grid[y][x]
            if visibility < 4 then -- Only draw fog for non-fully visible tiles
                local quad = fow_dither.get_quad(visibility)
                if quad then
                    love.graphics.draw(
                        fow_dither.sprite_sheet,
                        quad,
                        (x - 1) * fow_config.tile_size,
                        (y - 1) * fow_config.tile_size
                    )
                end
            end
        end
    end

    -- Reset canvas
    love.graphics.setCanvas()

    -- Mark the canvas as no longer dirty
    fow_draw.canvas_dirty = false
end

---Draw the fog of war
---@param fog_of_war table The main fog of war module
function fow_draw.draw(fog_of_war)
    if not fow_config.enabled or not fow_draw.canvas then return end

    -- Store current blend mode
    local r, g, b, a = love.graphics.getColor()
    local blendMode, blendAlphaMode = love.graphics.getBlendMode()

    -- Draw the fog canvas with multiply blend mode
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.draw(fow_draw.canvas, 0, 0)

    -- Restore previous state
    love.graphics.setBlendMode(blendMode, blendAlphaMode)
    love.graphics.setColor(r, g, b, a)
end

return fow_draw
