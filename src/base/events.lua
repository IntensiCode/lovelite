-- Event system for component communication
local events = {
    -- Store registered callbacks for each event key
    callbacks = {}
}

-- Register a callback for a specific event key
---@param key string The event key to register for
---@param callback function The callback function that will receive the event data
function events.register(key, callback)
    if not events.callbacks[key] then
        events.callbacks[key] = {}
    end
    table.insert(events.callbacks[key], callback)
    log.info("[events] Registered callback for event:", key)
end

-- Send an event to all registered callbacks for the given key
---@param key string The event key to send
---@param data table The event data to send to callbacks
function events.send(key, data)
    log.debug("[events] Sending event:", key, "with data:", data)
    assert(events.callbacks[key], "No callbacks registered for event: " .. key)
    
    for _, callback in ipairs(events.callbacks[key]) do
        callback(data)
    end
end

return events 