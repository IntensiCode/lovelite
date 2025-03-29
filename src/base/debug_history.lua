local debug_history = {}

-- Initialize history state
debug_history.command_history = {}
debug_history.history_position = 0
debug_history.output = {}
debug_history.max_output_lines = 10
debug_history.has_been_opened = false

-- Reset history state
function debug_history.reset()
    debug_history.command_history = {}
    debug_history.history_position = 0
    debug_history.output = {}
    debug_history.has_been_opened = false
end

-- Add a command to the history
function debug_history.add_command(command)
    if command and command ~= "" then
        table.insert(debug_history.command_history, command)
        debug_history.history_position = #debug_history.command_history + 1
    end
end

-- Get previous command from history
function debug_history.previous_command()
    if debug_history.history_position > 1 then
        debug_history.history_position = debug_history.history_position - 1
        return debug_history.command_history[debug_history.history_position]
    end
    return nil
end

-- Get next command from history
function debug_history.next_command()
    if debug_history.history_position < #debug_history.command_history then
        debug_history.history_position = debug_history.history_position + 1
        return debug_history.command_history[debug_history.history_position]
    elseif debug_history.history_position == #debug_history.command_history then
        debug_history.history_position = debug_history.history_position + 1
        return ""
    end
    return nil
end

-- Add output text
function debug_history.add_output(text)
    if type(text) ~= "string" then
        text = tostring(text)
    end
    
    -- Split text by newlines
    for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
        if line ~= "" then
            table.insert(debug_history.output, line)
        end
    end
    
    -- Limit output size
    while #debug_history.output > debug_history.max_output_lines do
        table.remove(debug_history.output, 1)
    end
end

-- Get output lines
function debug_history.get_output()
    return debug_history.output
end

-- Check if this is the first time opening
function debug_history.is_first_open()
    local first_open = not debug_history.has_been_opened
    debug_history.has_been_opened = true
    return first_open
end

return debug_history 