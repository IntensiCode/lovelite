local font = {
    tiny = nil,
    fancy = nil
}

-- Font anchor points
font.anchor = {
    top_left = 1,
    top_center = 2,
    top_right = 3,
    center_left = 4,
    center = 5,
    center_right = 6,
    bottom_left = 7,
    bottom_center = 8,
    bottom_right = 9
}

function font.load()
    -- Load tiny bitmap font
    local success, result = pcall(function()
        return love.graphics.newFont("assets/fonts/font_tiny.fnt")
    end)
    if success then
        font.tiny = result
    else
        print("Failed to load tiny font:", result)
    end

    -- Load fancy font
    success, result = pcall(function()
        return love.graphics.newFont("assets/fonts/font_fancy.fnt")
    end)
    if success then
        font.fancy = result
    else
        print("Failed to load fancy font:", result)
    end
end

-- Draw text with specified anchor point
function font.draw_text(text, x, y, anchor, font_type)
    local prev_font = love.graphics.getFont()
    local target_font = font_type or font.fancy -- Default to fancy font if not specified
    love.graphics.setFont(target_font)
    
    local text_width = target_font:getWidth(text)
    local text_height = target_font:getHeight()
    
    -- Calculate position based on anchor
    local draw_x, draw_y = x, y
    
    -- Horizontal alignment
    if anchor == font.anchor.top_center or 
       anchor == font.anchor.center or 
       anchor == font.anchor.bottom_center then
        draw_x = x - text_width / 2
    elseif anchor == font.anchor.top_right or 
           anchor == font.anchor.center_right or 
           anchor == font.anchor.bottom_right then
        draw_x = x - text_width
    end
    
    -- Vertical alignment
    if anchor == font.anchor.center_left or 
       anchor == font.anchor.center or 
       anchor == font.anchor.center_right then
        draw_y = y - text_height / 2
    elseif anchor == font.anchor.bottom_left or 
           anchor == font.anchor.bottom_center or 
           anchor == font.anchor.bottom_right then
        draw_y = y - text_height
    end
    
    -- Draw the text
    love.graphics.print(text, draw_x, draw_y)
    
    -- Restore previous font
    love.graphics.setFont(prev_font)
end

-- Add font to global game variable
_game = _game or {}
_game.font = font

return font 