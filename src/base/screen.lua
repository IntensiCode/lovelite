local screen = {
    current = nil,       -- Will be set in init
    screens = {},        -- Table to store screen modules
    initialized = {},    -- Track which screens have been initialized
    block_update = false -- Flag to block updates
}

function screen.load()
    love.update = function(dt)
        -- Skip update if blocked (e.g., by console)
        if screen.block_update then return end

        local current_screen = screen.get_current()
        current_screen.update(dt)
    end

    love.draw = function()
        local current_screen = screen.get_current()
        current_screen.draw()
    end

    love.resize = function(w, h)
        local current_screen = screen.get_current()
        current_screen.resize(w, h)
    end
end

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
    should_reset = should_reset ~= false -- Default to true if not specified

    if not screen.screens[name] then
        error("No such screen: " .. name)
    end

    -- Detach current screen if one exists
    if screen.current and screen.screens[screen.current] then
        local current_screen = screen.screens[screen.current]
        if current_screen.detach then
            current_screen.detach()
        end
    end

    -- Load the screen with reset flag
    screen.screens[name].load({ reset = should_reset })

    -- Attach the new screen
    if screen.screens[name].attach then
        screen.screens[name].attach()
    end

    screen.current = name
end

return screen
