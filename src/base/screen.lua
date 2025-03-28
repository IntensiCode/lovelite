local screen = {
    current = nil,     -- Will be set in init
    screens = {},      -- Table to store screen modules
    initialized = {}   -- Track which screens have been initialized
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
---@param should_reset boolean? Whether to reset the screen state (default: true)
function screen.switch_to(name, should_reset)
    should_reset = should_reset ~= false  -- Default to true if not specified
    
    if not screen.screens[name] then
        error("No such screen: " .. name)
    end

    -- Load the screen with reset flag
    screen.screens[name].load({ reset = should_reset })
    screen.current = name
end

return screen
