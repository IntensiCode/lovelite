local debug_console_ui = {}

-- Draw the console
function debug_console_ui.draw(state)
    if not state.visible then return end
    
    local lg = love.graphics
    
    -- Save current graphics state
    lg.push()
    
    -- Use the debug font if available
    local default_font = lg.getFont()
    local font = default_font
    font = DI.font.tiny
    lg.setFont(font)
    
    local width, height
    -- Get dimensions from camera if available
    width, height = DI.camera.getDimensions()
    
    local line_height = font:getHeight() * 1.2
    local console_height = line_height * state.history.max_output_lines + state.command_line_height
    
    -- Draw semi-transparent game overlay
    lg.setColor(0, 0, 0, 0.4) -- More transparent overlay
    lg.rectangle("fill", 0, 0, width, height)
    
    -- Draw console background
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill", 0, 0, width, console_height)
    
    -- Draw output lines - move up by 4 pixels
    lg.setColor(1, 1, 1, 1)
    local output_lines = state.history.get_output()
    for i, line in ipairs(output_lines) do
        lg.print(line, 5, (i - 1) * line_height + 5 - 4)
    end
    
    -- Draw separator line above command line
    local input_y = state.history.max_output_lines * line_height
    lg.setColor(0.6, 0.6, 0.6, 0.8)
    lg.rectangle("fill", 0, input_y, width, 1)
    
    -- Draw input line background
    lg.setColor(0.15, 0.15, 0.15, 0.8)
    lg.rectangle("fill", 0, input_y + 1, width, state.command_line_height - 1)
    
    -- Draw separator line below command line
    lg.setColor(0.6, 0.6, 0.6, 0.8)
    lg.rectangle("fill", 0, input_y + state.command_line_height, width, 1)
    
    -- Draw prompt and input text
    lg.setColor(0.2, 0.8, 0.2, 1)
    lg.print("> " .. state.input_text, 5, input_y + (state.command_line_height - font:getHeight()) / 2)
    
    -- Draw cursor
    if math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local cursor_x = font:getWidth("> " .. string.sub(state.input_text, 1, state.cursor_position))
        local cursor_y = input_y + (state.command_line_height - font:getHeight()) / 2
        lg.rectangle("fill", 5 + cursor_x, cursor_y, 2, font:getHeight())
    end
    
    -- Restore font
    lg.setFont(default_font)
    
    -- Restore previous graphics state
    lg.pop()
end

return debug_console_ui 