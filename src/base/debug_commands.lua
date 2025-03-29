local debug_commands = {}

-- Command registry
debug_commands.commands = {}

-- Add a command to the registry
---@param name string The command name
---@param handler function The command handler function
---@param help string Optional help text for the command
function debug_commands.add_command(name, handler, help)
    log.debug("Registering command: '" .. name .. "'")
    debug_commands.commands[name] = {
        handler = handler,
        help = help or "No help available"
    }
    log.debug("Command registry now has " .. table.count(debug_commands.commands) .. " commands")
end

-- Execute a command
---@param command string The command to execute
---@param args table Arguments for the command
---@return string|nil The command's output or nil if command not found
function debug_commands.execute(command, args)
    log.debug("debug_commands.execute called with command: '" .. tostring(command) .. "'")
    
    if not command then
        log.debug("No command specified")
        return "Error: No command specified"
    end
    
    -- Diagnostic check for backticks
    if command:find("`") then
        log.warn("DIAGNOSTIC: Backtick found in command at debug_commands.execute: '" .. command .. "'")
        -- Get byte codes for command for detailed diagnosis
        local bytes = {}
        for i = 1, #command do
            table.insert(bytes, string.byte(command, i))
        end
        log.warn("DIAGNOSTIC: Command bytes: " .. table.concat(bytes, ", "))
    end
    
    log.debug("Looking up command in registry. Registry has " .. table.count(debug_commands.commands) .. " commands")
    
    -- Debug: print all registered commands
    local command_names = {}
    for cmd_name, _ in pairs(debug_commands.commands) do
        table.insert(command_names, "'" .. cmd_name .. "'")
    end
    log.debug("Available commands: " .. table.concat(command_names, ", "))
    
    if debug_commands.commands[command] then
        log.debug("Found handler for command: '" .. command .. "'")
        local result
        local success, err = pcall(function()
            log.debug("Executing handler for command: '" .. command .. "'")
            result = debug_commands.commands[command].handler(unpack(args))
            log.debug("Handler execution completed. Result: " .. (result or "nil"))
        end)
        
        if success then
            log.debug("Command executed successfully")
            return result
        else
            log.debug("Error during command execution: " .. tostring(err))
            return "Error executing command: " .. tostring(err)
        end
    else
        log.debug("Unknown command: '" .. command .. "'")
        log.debug("Case sensitivity check - looking for variations of the command")
        
        -- Try case-insensitive match as a fallback
        for cmd_name, cmd_data in pairs(debug_commands.commands) do
            if string.lower(cmd_name) == string.lower(command) then
                log.debug("Found case-insensitive match: '" .. cmd_name .. "' for command '" .. command .. "'")
                log.debug("Executing case-insensitive match")
                
                local result
                local success, err = pcall(function()
                    result = cmd_data.handler(unpack(args))
                end)
                
                if success then
                    return result
                else
                    return "Error executing command: " .. tostring(err)
                end
            end
        end
        
        return "Unknown command: " .. command
    end
end

-- Register default commands
function debug_commands.register_defaults()
    -- Add help command
    debug_commands.add_command("help", function(command)
        log.debug("help command handler called with arg: " .. (command or "nil"))
        
        if command then
            if debug_commands.commands[command] then
                return command .. ": " .. debug_commands.commands[command].help
            else
                return "Unknown command: " .. command
            end
        else
            local result = "Available commands:"
            local commands = {}
            for name, _ in pairs(debug_commands.commands) do
                table.insert(commands, name)
            end
            table.sort(commands)
            
            for _, name in ipairs(commands) do
                result = result .. "\n  " .. name
            end
            log.debug("help command returning list with " .. #commands .. " commands")
            return result
        end
    end, "Show help for commands. Usage: help [command]")
end

-- Parse a command string into command and arguments
-- Returns { command = string, args = table, has_backtick = boolean, starts_with_backtick = boolean }
function debug_commands.parse(command_string)
    if not command_string or command_string == "" then
        return nil
    end
    
    -- Check for backticks in command
    local has_backtick = command_string:find("`") ~= nil
    
    -- Parse command into parts
    local parts = {}
    for part in string.gmatch(command_string, "%S+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then
        return nil
    end
    
    -- Get command and remove it from parts
    local command = parts[1]
    table.remove(parts, 1)
    
    -- Check if command starts with backtick
    local starts_with_backtick = command:sub(1, 1) == "`"
    
    -- Return the parsed information
    return {
        command = command,
        args = parts,
        has_backtick = has_backtick,
        starts_with_backtick = starts_with_backtick
    }
end

-- Initialize
log.debug("Initializing debug_commands module")
debug_commands.register_defaults()
log.debug("Initialized debug_commands with " .. table.count(debug_commands.commands) .. " commands")

return debug_commands 