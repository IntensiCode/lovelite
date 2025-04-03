local keys = {
    shortcuts = {}, -- Table to store all registered shortcuts
    interceptors = {}, -- Table to store input interceptors (newest first)
}

--[[
    Key Input Handling System
    
    This module provides a system for handling keyboard input with two mechanisms:
    
    1. Interceptors: Used for modal UI components (like the debug console)
       - Interceptors are checked first in order of registration (newest first)
       - Each interceptor can explicitly handle specific keys by returning true
       - If an interceptor handles a key, no further processing occurs
       - Keys not handled by interceptors (return false) fall through to shortcuts
    
    2. Shortcuts: Keyboard shortcuts for game functions
       - Only processed if no interceptor handled the key
       - Can be simple key bindings or include modifiers (ctrl, alt, shift)
       - Can be added/removed dynamically with add_shortcut/remove_shortcut
       - Can be screen-specific by registering/unregistering when screens change
    
    This design allows UI components to selectively intercept keys they care about
    while allowing other keys to be handled by active shortcuts.
]]

-- Initialize and register global keyboard callbacks
function keys.load()
    love.keypressed = function(key)
        local ok, _ = xpcall(
            function() return keys.keypressed(key) end,
            function(err) log.handle_error(err, "keypressed handler") end
        )
        return ok
    end

    love.textinput = function(text)
        local ok, _ = xpcall(
            function() return keys.textinput(text) end,
            function(err) log.handle_error(err, "textinput handler") end
        )
        return ok
    end
end

-- Helper function to create a shortcut key
local function make_shortcut_key(key, modifiers)
    modifiers = modifiers or {}
    local key_str = key

    -- Sort modifiers for consistency
    table.sort(modifiers)

    -- Add modifiers to key string
    for _, mod in ipairs(modifiers) do
        key_str = mod .. "+" .. key_str
    end

    return key_str
end

-- Shorter alias for add_shortcut with the previous signature style
-- @param key string The key to bind
-- @param callback function The function to call when the key is pressed
-- @param modifiers table Optional array of modifiers (ctrl, alt, shift)
-- @param description string Optional description of the shortcut
-- @param scope string Optional scope for the shortcut
-- @return string Shortcut ID that can be used to remove it later
function keys.add(key, callback, modifiers, description, scope)
    return keys.add_shortcut(key, {
        callback = callback,
        modifiers = modifiers,
        description = description,
        scope = scope,
    })
end

-- Add a shortcut
-- Returns the shortcut ID that can be used to remove it later
-- @param key string The key to bind
-- @param opts table Options including callback, modifiers, description, and scope
function keys.add_shortcut(key, opts)
    opts = opts or {}
    local callback = opts.callback
    local modifiers = opts.modifiers or {}
    local description = opts.description or "No description"
    local scope = opts.scope

    local shortcut_key = make_shortcut_key(key, modifiers)

    -- Assert the shortcut doesn't already exist (skip in test mode)
    if keys.shortcuts[shortcut_key] then
        log.assert(
            false,
            "Shortcut '%s' already exists! Cannot register duplicate shortcuts.",
            shortcut_key
        )
    end

    -- Assert the callback is valid (skip in test mode)
    log.assert(
        callback ~= nil,
        "Callback cannot be nil for shortcut '%s'",
        shortcut_key
    )
    log.assert(
        type(callback) == "function",
        "Callback must be a function for shortcut '%s', got %s instead",
        shortcut_key,
        type(callback)
    )

    -- Create the shortcut data
    local shortcut = {
        key = key,
        modifiers = modifiers,
        callback = callback,
        description = description,
        scope = scope,
    }

    -- Store the shortcut
    keys.shortcuts[shortcut_key] = shortcut

    return shortcut_key
end

-- Remove a shortcut by ID
function keys.remove_shortcut(shortcut_key)
    if keys.shortcuts[shortcut_key] then
        keys.shortcuts[shortcut_key] = nil
        return true
    end
    return false
end

-- Remove a shortcut by key and optional modifiers
function keys.remove_shortcut_by_key(key, modifiers)
    local shortcut_key = make_shortcut_key(key, modifiers)
    return keys.remove_shortcut(shortcut_key)
end

-- Remove all shortcuts that have the given scope
-- @param scope string The scope to remove shortcuts for
-- @return number The number of shortcuts removed
function keys.remove_shortcuts_by_scope(scope)
    if not scope then
        return 0
    end

    local count = 0
    local to_remove = {}

    -- Find all shortcuts with the given scope
    for id, shortcut in pairs(keys.shortcuts) do
        if shortcut.scope == scope then
            table.insert(to_remove, id)
        end
    end

    -- Remove all found shortcuts
    for _, id in ipairs(to_remove) do
        keys.shortcuts[id] = nil
        count = count + 1
    end

    return count
end

-- Register an input interceptor
-- An interceptor is a table with keypressed and/or textinput methods
-- Returns an ID that can be used to unregister the interceptor
function keys.register_interceptor(interceptor)
    local id = {} -- Use a unique table as ID
    table.insert(keys.interceptors, 1, { id = id, interceptor = interceptor })
    return id
end

-- Unregister an input interceptor by ID
function keys.unregister_interceptor(id)
    for i, entry in ipairs(keys.interceptors) do
        if entry.id == id then
            table.remove(keys.interceptors, i)
            return true
        end
    end
    return false
end

-- Handle key press events
function keys.keypressed(key)
    -- First, try all interceptors
    for _, entry in ipairs(keys.interceptors) do
        local interceptor = entry.interceptor
        if interceptor.keypressed and interceptor.keypressed(key) then
            return true -- Input was handled by interceptor
        end
    end

    -- If no interceptor handled the input, process shortcuts

    -- Check if any modifiers are pressed
    local modifiers = {}
    if love.keyboard.isDown("lalt", "ralt") then
        table.insert(modifiers, "alt")
    end
    if love.keyboard.isDown("lctrl", "rctrl") then
        table.insert(modifiers, "ctrl")
    end
    if love.keyboard.isDown("lshift", "rshift") then
        table.insert(modifiers, "shift")
    end

    -- Sort modifiers for consistency
    table.sort(modifiers)

    -- Create shortcut key to look up
    local shortcut_key = make_shortcut_key(key, modifiers)

    -- Find and execute the shortcut if it exists with modifiers
    local shortcut = keys.shortcuts[shortcut_key]
    if shortcut then
        shortcut.callback()
        return true
    end

    -- Only try fallback (key without modifiers) if no modifiers are actually pressed
    if #modifiers == 0 then
        -- Check for direct key match
        shortcut = keys.shortcuts[key]
        if shortcut then
            shortcut.callback()
            return true
        end
    end

    return false
end

-- Handle text input events
function keys.textinput(text)
    -- First, try all interceptors
    for _, entry in ipairs(keys.interceptors) do
        local interceptor = entry.interceptor
        if interceptor.textinput and interceptor.textinput(text) then
            return true -- Input was handled by interceptor
        end
    end

    -- For now, no default text input handling beyond interceptors
    return false
end

-- Get all registered shortcuts
-- @return table of shortcuts with id, key, modifiers, and description
function keys.get_all_shortcuts()
    local result = {}
    for id, shortcut in pairs(keys.shortcuts) do
        table.insert(result, {
            id = id,
            key = shortcut.key,
            modifiers = shortcut.modifiers,
            description = shortcut.description,
        })
    end
    return result
end

return keys
