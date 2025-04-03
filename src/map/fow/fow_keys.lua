-- FOW Keys Module
-- Manages keyboard shortcuts and input handling for fog of war functionality.
-- Provides bindings for toggling visibility, debug grid, and field of view modes.
-- Implements commands to adjust visibility radii and reveal the entire map.
-- Displays fog status information directly in the game console for development.

local FowKeys = {}
FowKeys.__index = FowKeys

--- Toggle fog of war visibility
function FowKeys:toggle_fog()
    local was_enabled = DI.fog_of_war.enabled
    DI.fog_of_war.set_enabled(not was_enabled)
    log.info("Fog of war " .. (DI.fog_of_war.enabled and "enabled" or "disabled"))
end

--- Toggle fog debug grid
function FowKeys:toggle_debug_grid()
    DI.fog_of_war.toggle_debug_grid()
end

--- Toggle field of view mode
function FowKeys:toggle_field_of_view()
    DI.fog_of_war.toggle_field_of_view_mode()
    log.info("Field of view mode " .. (DI.fog_of_war.field_of_view_mode and "enabled" or "disabled"))
end

--- Toggle rooftop hiding
function FowKeys:toggle_hide_rooftops()
    DI.fog_of_war.toggle_hide_rooftops()
    log.info("Rooftop hiding " .. (DI.fog_of_war.hide_rooftops and "enabled" or "disabled"))
end

--- Display detailed fog status
function FowKeys:display_status()
    local playerPos = ""
    if DI.player and DI.player.pos then
        playerPos = " Player pos: " .. math.floor(DI.player.pos.x) .. "," .. math.floor(DI.player.pos.y)
    end
    
    local visibility = ""
    if DI.player and DI.player.pos then
        local px = math.floor(DI.player.pos.x)
        local py = math.floor(DI.player.pos.y)
        if DI.fog_of_war.is_valid_position(px, py) then
            visibility = " Visibility: " .. DI.fog_of_war.grid[py][px]
        end
    end
    
    local status = "Fog: " .. (DI.fog_of_war.enabled and "ON" or "OFF") .. 
                  " FoV: " .. (DI.fog_of_war.field_of_view_mode and "ON" or "OFF") ..
                  " Rooftops: " .. (DI.fog_of_war.hide_rooftops and "HIDDEN" or "SHOWN") ..
                  " IR: " .. DI.fog_of_war.inner_radius .. 
                  " OR: " .. DI.fog_of_war.outer_radius ..
                  playerPos .. visibility
    
    log.info(status)
end

--- Reveal the entire map
function FowKeys:reveal_map()
    DI.fog_of_war.reveal_all()
    log.info("Revealed entire map")
end

--- Increase visibility radii
function FowKeys:increase_radius()
    DI.fog_of_war.inner_radius = DI.fog_of_war.inner_radius + 1
    DI.fog_of_war.outer_radius = DI.fog_of_war.outer_radius + 1
    log.info("Fog visibility radii: inner=" .. DI.fog_of_war.inner_radius .. ", outer=" .. DI.fog_of_war.outer_radius)
    DI.fog_of_war.prev_player_pos = nil -- Force update
end

--- Decrease visibility radii
function FowKeys:decrease_radius()
    DI.fog_of_war.inner_radius = math.max(1, DI.fog_of_war.inner_radius - 1)
    DI.fog_of_war.outer_radius = math.max(2, DI.fog_of_war.outer_radius - 1)
    log.info("Fog visibility radii: inner=" .. DI.fog_of_war.inner_radius .. ", outer=" .. DI.fog_of_war.outer_radius)
    DI.fog_of_war.prev_player_pos = nil -- Force update
end

--- Register fog of war keyboard shortcuts
function FowKeys:attach()
    local self = self
    
    -- Toggle fog of war
    DI.keys.add_shortcut("f", {
        callback = function() self:toggle_fog() end,
        description = "Toggle fog of war",
        scope = "fog_of_war"
    })
    
    -- Toggle fog debug grid (Shift+F)
    DI.keys.add_shortcut("f", {
        callback = function() self:toggle_debug_grid() end,
        modifiers = {"shift"},
        description = "Toggle fog debug grid",
        scope = "fog_of_war"
    })
    
    -- Display fog status (Alt+F)
    DI.keys.add_shortcut("f", {
        callback = function() self:display_status() end,
        modifiers = {"alt"},
        description = "Display fog status",
        scope = "fog_of_war"
    })
    
    -- Reveal entire map (Ctrl+F)
    DI.keys.add_shortcut("f", {
        callback = function() self:reveal_map() end,
        modifiers = {"ctrl"},
        description = "Reveal entire map",
        scope = "fog_of_war"
    })
    
    -- Increase fog visibility radii
    DI.keys.add_shortcut("+", {
        callback = function() self:increase_radius() end,
        description = "Increase fog visibility radii",
        scope = "fog_of_war"
    })
    
    -- Also register "=" as an alternative key for plus
    DI.keys.add_shortcut("=", {
        callback = function() self:increase_radius() end,
        description = "Increase fog visibility radii",
        scope = "fog_of_war"
    })
    
    -- Decrease fog visibility radii
    DI.keys.add_shortcut("-", {
        callback = function() self:decrease_radius() end,
        description = "Decrease fog visibility radii",
        scope = "fog_of_war"
    })
    
    -- Also register "_" as an alternative key for minus
    DI.keys.add_shortcut("_", {
        callback = function() self:decrease_radius() end,
        description = "Decrease fog visibility radii",
        scope = "fog_of_war"
    })
    
    -- Toggle field of view mode (Ctrl+Shift+F)
    DI.keys.add_shortcut("f", {
        callback = function() self:toggle_field_of_view() end,
        modifiers = {"ctrl", "shift"},
        description = "Toggle field of view mode",
        scope = "fog_of_war"
    })
    
    -- Toggle rooftop hiding (Ctrl+Alt+F)
    DI.keys.add_shortcut("f", {
        callback = function() self:toggle_hide_rooftops() end,
        modifiers = {"ctrl", "alt"},
        description = "Toggle rooftop hiding",
        scope = "fog_of_war"
    })
end

--- Unregister fog of war keyboard shortcuts
function FowKeys:detach()
    DI.keys.remove_shortcuts_by_scope("fog_of_war")
end

-- Create an instance
local fow_keys = setmetatable({}, FowKeys)

return fow_keys 