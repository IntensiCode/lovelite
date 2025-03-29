local fow_draw = {}

---Update the fog of war canvas based on the current grid state
---@param fog_of_war table The main fog of war module
function fow_draw.update_canvas(fog_of_war)
    if not fog_of_war.canvas or not fog_of_war.canvas_dirty then return end
    
    love.graphics.setCanvas(fog_of_war.canvas)
    love.graphics.clear(0, 0, 0, 1)  -- Start with completely black
    
    love.graphics.setBlendMode("alpha")
    
    -- Draw the transition zone (outer radius) with half transparency
    love.graphics.setColor(1, 1, 1, 0.5)  -- White with 50% opacity
    for y = 1, fog_of_war.size.y do
        for x = 1, fog_of_war.size.x do
            if fog_of_war.grid[y][x] >= 1 then
                love.graphics.rectangle(
                    "fill",
                    (x - 1) * fog_of_war.tile_size,
                    (y - 1) * fog_of_war.tile_size,
                    fog_of_war.tile_size,
                    fog_of_war.tile_size
                )
            end
        end
    end
    
    -- Draw the fully visible zone (inner radius) with full visibility
    love.graphics.setColor(1, 1, 1, 1)  -- White with 100% opacity
    for y = 1, fog_of_war.size.y do
        for x = 1, fog_of_war.size.x do
            if fog_of_war.grid[y][x] >= 2 then
                love.graphics.rectangle(
                    "fill",
                    (x - 1) * fog_of_war.tile_size,
                    (y - 1) * fog_of_war.tile_size,
                    fog_of_war.tile_size,
                    fog_of_war.tile_size
                )
            end
        end
    end
    
    -- Reset graphics state
    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Mark the canvas as no longer dirty
    fog_of_war.canvas_dirty = false
end

---Draw the fog of war on screen
---@param fog_of_war table The main fog of war module
---@param translation_x number Camera translation X
---@param translation_y number Camera translation Y
function fow_draw.draw(fog_of_war, translation_x, translation_y)
    if not fog_of_war.enabled or not fog_of_war.canvas then return end
    
    -- Try a different rendering approach - this is experimental
    -- Three options provided:
    
    -- OPTION 1: Simple version using subtract blend mode
    fow_draw.draw_option1(fog_of_war)
    
    -- OPTION 2: The previous implementation
    -- fow_draw.draw_option2(fog_of_war)
    
    -- OPTION 3: Alternative using multiply approach 
    -- fow_draw.draw_option3(fog_of_war)
end

---Draw option 1: Using subtract blend mode
---@param fog_of_war table The main fog of war module
function fow_draw.draw_option1(fog_of_war)
    -- Save current graphics state
    local r, g, b, a = love.graphics.getColor()
    local currentBlendMode = love.graphics.getBlendMode()
    
    -- Draw black overlay
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(0, 0, 0, 0.7) -- Black with 70% opacity
    
    -- Cover entire map
    local mapWidth = fog_of_war.size.x * fog_of_war.tile_size
    local mapHeight = fog_of_war.size.y * fog_of_war.tile_size
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    
    -- Draw the visibility mask
    love.graphics.setBlendMode("subtract")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(fog_of_war.canvas, 0, 0)
    
    -- Restore previous graphics state
    love.graphics.setBlendMode(currentBlendMode)
    love.graphics.setColor(r, g, b, a)
end

---Draw option 2: Previous implementation using add blend mode
---@param fog_of_war table The main fog of war module
function fow_draw.draw_option2(fog_of_war)
    -- Save current graphics state
    local r, g, b, a = love.graphics.getColor()
    local currentBlendMode = love.graphics.getBlendMode()
    
    -- First, draw a black rectangle over the entire game area
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(0, 0, 0, 1)
    
    local mapWidth = fog_of_war.size.x * fog_of_war.tile_size
    local mapHeight = fog_of_war.size.y * fog_of_war.tile_size
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    
    -- Then draw the fog canvas using "lighten" blend mode (approximated in LÖVE)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(fog_of_war.canvas, 0, 0)
    
    -- Restore previous graphics state
    love.graphics.setBlendMode(currentBlendMode)
    love.graphics.setColor(r, g, b, a)
end

---Draw option 3: Alternative using multiply blend mode
---@param fog_of_war table The main fog of war module
function fow_draw.draw_option3(fog_of_war)
    -- Save current graphics state
    local r, g, b, a = love.graphics.getColor()
    local currentBlendMode = love.graphics.getBlendMode()
    
    -- Draw using multiply blend mode
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Use a stencil to limit drawing to the map area
    love.graphics.stencil(function()
        local mapWidth = fog_of_war.size.x * fog_of_war.tile_size
        local mapHeight = fog_of_war.size.y * fog_of_war.tile_size
        love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    end, "replace", 1)
    
    love.graphics.setStencilTest("greater", 0)
    love.graphics.draw(fog_of_war.canvas, 0, 0)
    love.graphics.setStencilTest()
    
    -- Restore previous graphics state
    love.graphics.setBlendMode(currentBlendMode)
    love.graphics.setColor(r, g, b, a)
end

return fow_draw 