-- Fog of War Module
-- Main fog of war implementation for the LoveLite game engine.
-- Manages visibility of the map with gradual fog levels and field of view functionality.
-- Coordinates between specialized modules for rendering, memory, and ray casting.
-- Provides interface for other game systems to interact with fog of war mechanics.

local fow_config = require("src.map.fow.fow_config")
local fow_debug = require("src.map.fow.fow_debug")
local fow_dither = require("src.map.fow.fow_dither")
local fow_draw = require("src.map.fow.fow_draw")
local fow_keys = require("src.map.fow.fow_keys")
local fow_memory = require("src.map.fow.fow_memory")
local fow_reveal = require("src.map.fow.fow_reveal")
local pos = require("src.base.pos")

---@class FogOfWar
local fog_of_war = {}

---Initialize the fog of war grid
---@param opts? {reset: boolean, inner_radius: number?, outer_radius: number?, field_of_view_mode: boolean?, hide_rooftops: boolean?} Configuration options
function fog_of_war.load(opts)
    opts = opts or { reset = true }

    log.assert(DI.dungeon, "Dungeon not available")
    log.assert(DI.player, "Player not available")

    if opts.reset then
        -- Get map dimensions from dungeon
        local map_width = DI.dungeon.map.width
        local map_height = DI.dungeon.map.height
        fow_config.tile_size = DI.dungeon.tile_size

        -- Set size
        fow_config.size = pos.new(map_width, map_height)

        -- Initialize grids
        fow_memory.init(0)

        -- Set options
        if opts.inner_radius then
            fow_config.inner_radius = opts.inner_radius
        end

        if opts.outer_radius then
            fow_config.outer_radius = opts.outer_radius
        end

        if opts.field_of_view_mode ~= nil then
            fow_config.field_of_view_mode = opts.field_of_view_mode
        end

        if opts.hide_rooftops ~= nil then
            fow_config.hide_rooftops = opts.hide_rooftops
        end

        -- Initialize dither patterns
        fow_dither.create_sprite_sheet()

        -- Reset state
        fow_config.prev_player_pos = nil

        -- Register debug commands
        fow_debug.register_commands(fog_of_war)

        -- Immediately reveal the area around player
        fog_of_war.reveal_around(DI.player.pos)
        log.debug("Initial fog of war visibility set around player")
    end
end

---Check if a tile position is valid in the grid
---@param x number Tile X coordinate
---@param y number Tile Y coordinate
---@return boolean is_valid Whether the position is within the grid
function fog_of_war.is_valid_position(x, y)
    return fow_reveal.is_valid_position(x, y)
end

---Reveal tiles around a position within the visibility radius
---@param center_pos pos Position to reveal around (in tiles, centered)
function fog_of_war.reveal_around(center_pos)
    assert(center_pos, "center_pos is required")
    fow_reveal.reveal_around(center_pos)
end

---Reveal the entire map (for debugging)
function fog_of_war.reveal_all()
    fow_reveal.reveal_all()
end

---Toggle fog of war on/off
---@param enabled boolean Whether fog of war should be enabled
function fog_of_war.set_enabled(enabled)
    fow_config.enabled = enabled
end

---Toggle field of view mode on/off
---@param enabled boolean Whether field of view mode should be enabled
function fog_of_war.set_field_of_view_mode(enabled)
    -- Update the field of view mode
    local changed = fow_reveal.set_field_of_view_mode(enabled)

    if changed then
        -- We force a reveal by invalidating prev_player_pos
        fow_config.prev_player_pos = nil
        fog_of_war.reveal_around(DI.player.pos)

        if enabled then
            log.debug("Field of view mode enabled")
        else
            log.debug("Traditional fog of war mode enabled")
        end
    end
end

---Toggle field of view mode on/off
function fog_of_war.toggle_field_of_view_mode()
    fog_of_war.set_field_of_view_mode(not fow_config.field_of_view_mode)
end

---Toggle rooftop hiding on/off
---@param enabled boolean Whether rooftops should be hidden with medium fog
function fog_of_war.set_hide_rooftops(enabled)
    -- If we're toggling to the same state, do nothing
    if fow_config.hide_rooftops == enabled then
        return
    end

    fow_config.hide_rooftops = enabled

    -- Force an update based on player position
    if DI.player then
        -- We force a reveal by invalidating prev_player_pos
        fow_config.prev_player_pos = nil
        fog_of_war.reveal_around(DI.player.pos)
    end

    if enabled then
        log.debug("Rooftop hiding enabled")
    else
        log.debug("Rooftop hiding disabled")
    end
end

---Toggle rooftop hiding on/off
function fog_of_war.toggle_hide_rooftops()
    fog_of_war.set_hide_rooftops(not fow_config.hide_rooftops)
end

---Update the fog of war based on player position
function fog_of_war.update()
    if not fow_config.enabled then
        return
    end

    -- Reveal area around player
    fog_of_war.reveal_around(DI.player.pos)
end

---Draw the fog of war
---@param translation_x number Camera translation X
---@param translation_y number Camera translation Y
function fog_of_war.draw(translation_x, translation_y)
    fow_draw.draw(translation_x, translation_y)
end

function fog_of_war.draw_debug_grid()
    fow_debug.draw_grid()
end

function fog_of_war.toggle_debug_grid()
    fow_debug.toggle_grid()
end

function fog_of_war.attach()
    fow_keys:attach()
end

-- Unregister fog of war keyboard shortcuts
function fog_of_war.detach()
    fow_keys:detach()
end

return fog_of_war
