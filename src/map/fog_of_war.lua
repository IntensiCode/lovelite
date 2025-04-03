-- Fog of War Module
-- Main fog of war implementation for the LoveLite game engine.
-- Manages visibility of the map with gradual fog levels and field of view functionality.
-- Coordinates between specialized modules for rendering, memory, and ray casting.
-- Provides interface for other game systems to interact with fog of war mechanics.

local pos = require("src.base.pos")
local fow_debug = require("src.map.fow.fow_debug")
local fow_reveal = require("src.map.fow.fow_reveal")
local fow_draw = require("src.map.fow.fow_draw")
local fow_keys = require("src.map.fow.fow_keys")
local fow_dither = require("src.map.fow.fow_dither")

---@class FogOfWar
---@field grid number[][] Grid tracking tile visibility: 0=unseen, 1=edge/heavy dither, 2=medium dither, 3=light dither, 4=visible
---@field memory_grid number[][] Grid tracking maximum visibility each tile has achieved
---@field size pos The size of the grid in tiles
---@field inner_radius number Radius of full visibility around player (in tiles)
---@field outer_radius number Radius of partial visibility around player (in tiles)
---@field canvas love.Canvas The canvas to draw the fog on
---@field tile_size number Size of a tile in pixels
---@field enabled boolean Whether fog of war is enabled
---@field field_of_view_mode boolean Whether field of view mode is enabled (areas outside view are darkened)
---@field hide_rooftops boolean Whether rooftops should be hidden with medium fog
---@field canvas_dirty boolean Whether the canvas needs to be redrawn
---@field prev_player_pos pos The last position where the player was
local fog_of_war = {
    grid = {},
    memory_grid = {},
    size = pos.new(0, 0),
    inner_radius = 4,
    outer_radius = 8, -- Increased to accommodate more fog levels
    canvas = nil,
    tile_size = 0,
    enabled = true,
    field_of_view_mode = true, -- Default to field of view mode
    hide_rooftops = true, -- Default to hiding rooftops
    canvas_dirty = true,
    prev_player_pos = nil
}

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
        fog_of_war.tile_size = DI.dungeon.tile_size

        -- Initialize grid to all unexplored (0)
        fog_of_war.grid = {}
        fog_of_war.memory_grid = {}
        for y = 1, map_height do
            fog_of_war.grid[y] = {}
            fog_of_war.memory_grid[y] = {}
            for x = 1, map_width do
                fog_of_war.grid[y][x] = 0
                fog_of_war.memory_grid[y][x] = 0
            end
        end

        -- Set size
        fog_of_war.size = pos.new(map_width, map_height)

        -- Create canvas for drawing the fog
        if love.graphics.isCreated then
            fog_of_war.canvas = love.graphics.newCanvas(
                map_width * fog_of_war.tile_size,
                map_height * fog_of_war.tile_size
            )
        end

        -- Set options
        if opts.inner_radius then
            fog_of_war.inner_radius = opts.inner_radius
        end

        if opts.outer_radius then
            fog_of_war.outer_radius = opts.outer_radius
        end
        
        if opts.field_of_view_mode ~= nil then
            fog_of_war.field_of_view_mode = opts.field_of_view_mode
        end
        
        if opts.hide_rooftops ~= nil then
            fog_of_war.hide_rooftops = opts.hide_rooftops
        end

        -- Initialize dither patterns
        fow_dither.create_sprite_sheet()

        -- Reset state
        fog_of_war.canvas_dirty = true
        fog_of_war.prev_player_pos = nil

        -- Register debug commands
        fow_debug.register_commands(fog_of_war)

        -- Immediately reveal the area around player
                fog_of_war.reveal_around(DI.player.pos)
                fow_draw.update_canvas(fog_of_war)
                log.debug("Initial fog of war visibility set around player")
    end
end

---Check if a tile position is valid in the grid
---@param x number Tile X coordinate
---@param y number Tile Y coordinate
---@return boolean is_valid Whether the position is within the grid
function fog_of_war.is_valid_position(x, y)
    return fow_reveal.is_valid_position(fog_of_war, x, y)
end

---Reveal tiles around a position within the visibility radius
---@param center_pos pos Position to reveal around (in tiles, centered)
function fog_of_war.reveal_around(center_pos)
    local changed = fow_reveal.reveal_around(fog_of_war, center_pos)
    if changed then
        fog_of_war.canvas_dirty = true
    end
end

---Reveal the entire map (for debugging)
function fog_of_war.reveal_all()
    local changed = fow_reveal.reveal_all(fog_of_war)
    if changed then
        fog_of_war.canvas_dirty = true
        fow_draw.update_canvas(fog_of_war)
    end
    log.debug("Revealed entire map")
end

---Toggle fog of war on/off
---@param enabled boolean Whether fog of war should be enabled
function fog_of_war.set_enabled(enabled)
    -- If we're toggling to the same state, do nothing
    if fog_of_war.enabled == enabled then return end

    fog_of_war.enabled = enabled
    fog_of_war.canvas_dirty = true

    -- Always update the canvas immediately after toggling
    fow_draw.update_canvas(fog_of_war)
end

---Toggle field of view mode on/off
---@param enabled boolean Whether field of view mode should be enabled
function fog_of_war.set_field_of_view_mode(enabled)
    -- Update the field of view mode
    local changed = fow_reveal.set_field_of_view_mode(fog_of_war, enabled)
    
    if changed then
        fog_of_war.canvas_dirty = true
        
        -- Force an update based on player position
        if DI.player then
            -- We force a reveal by invalidating prev_player_pos
            fog_of_war.prev_player_pos = nil
            fog_of_war.reveal_around(DI.player.pos)
        end
        
        -- Always update the canvas immediately after toggling
        fow_draw.update_canvas(fog_of_war)
        
        if enabled then
            log.debug("Field of view mode enabled")
        else
            log.debug("Traditional fog of war mode enabled")
        end
    end
end

---Toggle field of view mode on/off
function fog_of_war.toggle_field_of_view_mode()
    fog_of_war.set_field_of_view_mode(not fog_of_war.field_of_view_mode)
end

---Toggle rooftop hiding on/off
---@param enabled boolean Whether rooftops should be hidden with medium fog
function fog_of_war.set_hide_rooftops(enabled)
    -- If we're toggling to the same state, do nothing
    if fog_of_war.hide_rooftops == enabled then return end

    fog_of_war.hide_rooftops = enabled
    fog_of_war.canvas_dirty = true
    
    -- Force an update based on player position
    if DI.player then
        -- We force a reveal by invalidating prev_player_pos
        fog_of_war.prev_player_pos = nil
        fog_of_war.reveal_around(DI.player.pos)
    end
    
    -- Always update the canvas immediately after toggling
    fow_draw.update_canvas(fog_of_war)
    
    if enabled then
        log.debug("Rooftop hiding enabled")
    else
        log.debug("Rooftop hiding disabled")
    end
end

---Toggle rooftop hiding on/off
function fog_of_war.toggle_hide_rooftops()
    fog_of_war.set_hide_rooftops(not fog_of_war.hide_rooftops)
end

---Update the fog of war based on player position
---@param dt number Delta time
function fog_of_war.update(dt)
    if not fog_of_war.enabled then return end

    -- Reveal area around player
    fog_of_war.reveal_around(DI.player.pos)

    -- Always update the canvas during the first few frames to ensure it's visible
    if fog_of_war.canvas_dirty or not fog_of_war.prev_player_pos then
        fow_draw.update_canvas(fog_of_war)
    end
end

---Draw the fog of war
---@param translation_x number Camera translation X
---@param translation_y number Camera translation Y
function fog_of_war.draw(translation_x, translation_y)
    if not fog_of_war.enabled or not fog_of_war.canvas then return end
    fow_draw.draw(fog_of_war)
end

function fog_of_war.draw_debug_grid()
    fow_debug.draw_grid(fog_of_war)
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
