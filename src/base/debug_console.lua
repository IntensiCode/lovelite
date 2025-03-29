local debug_history = require("src.base.debug_history")
local debug_console_ui = require("src.base.debug_console_ui")

local debug_console = {}

debug_console.visible = false
debug_console.input_text = ""
debug_console.cursor_position = 0
debug_console.command_line_height = 20 -- Increased command line height
debug_console.interceptor_id = nil     -- Store the interceptor ID
debug_console.swallow_backtick = false -- Flag to swallow backtick character
debug_console.history = debug_history  -- Reference to history module

function debug_console:handle_backspace()
    if self.cursor_position > 0 then
        self.input_text = string.sub(self.input_text, 1, self.cursor_position - 1) ..
            string.sub(self.input_text, self.cursor_position + 1)
        self.cursor_position = self.cursor_position - 1
    end
end

function debug_console:handle_delete()
    self.input_text = string.sub(self.input_text, 1, self.cursor_position) ..
        string.sub(self.input_text, self.cursor_position + 2)
end

function debug_console:handle_previous_command()
    local prev_command = debug_history.previous_command()
    if prev_command then
        self.input_text = prev_command
        self.cursor_position = #prev_command
    end
end

function debug_console:handle_next_command()
    local next_command = debug_history.next_command()
    if next_command then
        self.input_text = next_command
        self.cursor_position = #next_command
    end
end

function debug_console:toggle()
    self.visible = not self.visible

    DI.screen.block_update = self.visible

    if self.visible then
        self.swallow_backtick = true
        local console = self -- Store reference to self for closure
        self.interceptor_id = DI.keys.register_interceptor({
            keypressed = function(key) return console:keypressed(key) end,
            textinput = function(text) return console:textinput(text) end
        })
    else
        if self.interceptor_id then
            DI.keys.unregister_interceptor(self.interceptor_id)
            self.interceptor_id = nil
        end
    end

    if self.visible then
        self.input_text = ""
        self.cursor_position = 0

        if debug_history.is_first_open() then
            self.input_text = "help"
            self:execute()
            debug_history.add_output("Type 'help [command]' for more information about a command.")
        end
    end
end

function debug_console:execute()
    if self.input_text == "" then
        return
    end

    debug_history.add_output("> " .. self.input_text)
    debug_history.add_command(self.input_text)

    local parsed = DI.debug_commands.parse(self.input_text)
    if parsed then
        local result = DI.debug_commands.execute(parsed.command, parsed.args)
        if result then debug_history.add_output(result) end
    end

    self.input_text = ""
    self.cursor_position = 0
end

function debug_console:keypressed(key)
    if not self.visible then return false end

    if key == "return" or key == "kpenter" then
        self:execute()
    elseif key == "escape" then
        self:toggle()
    elseif key == "backspace" then
        self:handle_backspace()
    elseif key == "delete" then
        self:handle_delete()
    elseif key == "left" then
        self.cursor_position = math.max(0, self.cursor_position - 1)
    elseif key == "right" then
        self.cursor_position = math.min(#self.input_text, self.cursor_position + 1)
    elseif key == "up" then
        self:handle_previous_command()
    elseif key == "down" then
        self:handle_next_command()
    elseif key == "home" then
        self.cursor_position = 0
    elseif key == "end" then
        self.cursor_position = #self.input_text
    end

    return true
end

function debug_console:textinput(text)
    if not self.visible then return false end

    if text == "`" then
        if self.swallow_backtick then
            self.swallow_backtick = false
            return true
        end

        -- If command line is empty, close the console when backtick is pressed
        if self.input_text == "" then
            self:toggle()
            return true
        end
        -- Otherwise, add the backtick to the command line
    end

    self.input_text = string.sub(self.input_text, 1, self.cursor_position) ..
        text ..
        string.sub(self.input_text, self.cursor_position + 1)
    self.cursor_position = self.cursor_position + #text
    return true
end

function debug_console:draw()
    debug_console_ui.draw(debug_console)
end

return debug_console
