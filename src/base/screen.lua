local screen = {
    current = "title", -- Start with title screen
    screens = {}       -- Table to store screen modules
}

---Register a screen module
---@param name string The name of the screen
---@param module table The screen module
function screen.register(name, module)
    screen.screens[name] = module
end

---Get the current screen module
---@return table The current screen module
function screen.get_current()
    return screen.screens[screen.current]
end

---Switch to a different screen
---@param name string The name of the screen to switch to
function screen.switch_to(name)
    if screen.screens[name] then
        screen.current = name
    end
end

-- Add screen to global game variable
_game = _game or {}
_game.screen = screen

return screen
