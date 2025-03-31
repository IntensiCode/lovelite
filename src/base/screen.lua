local screen = {
    current = nil,        -- Will be set in init
    screens = {},         -- Table to store screen modules
    initialized = {},     -- Track which screens have been initialized
    block_update = false, -- Flag to block updates
    overlays = {}         -- List of overlay modules that can have update/draw functions
}

local function overlays_each(method_name, ...)
    local args = { ... }
    list.each(screen.overlays, function(overlay)
        local method = overlay[method_name]
        if method then
            method(unpack(args))
        end
    end)
end

--- Run a function with error catching using xpcall
--- @param callback function The function to run safely
local function run_catching(callback)
    return xpcall(callback, log.handle_error)
end

function screen.load()
    love.update = function(dt)
        run_catching(function()
            if not screen.block_update then
                screen.get_current().update(dt)
            end
            overlays_each("update", dt)
        end)
    end

    love.draw = function()
        run_catching(function()
            screen.get_current().draw()
            overlays_each("draw")
        end)
    end

    love.resize = function(w, h)
        run_catching(function()
            screen.get_current().resize(w, h)
            overlays_each("resize", w, h)
        end)
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

---Add an overlay module to the screen system
---@param overlay table The overlay module (can have update, draw, resize functions)
function screen.add_overlay(overlay)
    list.add(screen.overlays, overlay)
end

---Remove an overlay from the screen system
---@param overlay table The overlay module to remove
function screen.remove_overlay(overlay)
    list.remove_item(screen.overlays, overlay)
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
            run_catching(function()
                current_screen.detach()
            end)
        end
    end

    -- Load the screen with reset flag
    run_catching(function()
        screen.screens[name].load({ reset = should_reset })
    end)

    -- Attach the new screen
    if screen.screens[name].attach then
        run_catching(function()
            screen.screens[name].attach()
        end)
    end

    screen.current = name
end

return screen
