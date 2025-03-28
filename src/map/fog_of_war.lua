local pos = require("src.base.pos")
local fow_debug = require("src.map.fow_debug")
local fow_reveal = require("src.map.fow_reveal") 
local fow_draw = require("src.map.fow_draw")
local fow_keys = require("src.map.fow_keys")

---@class FogOfWar
---@field grid number[][] Grid tracking tile visibility: 0=unseen, 1=edge, 2=visible
---@field size pos The size of the grid in tiles
---@field inner_radius number Radius of full visibility around player (in tiles)
---@field outer_radius number Radius of partial visibility around player (in tiles)
---@field canvas love.Canvas The canvas to draw the fog on
---@field tile_size number Size of a tile in pixels
---@field enabled boolean Whether fog of war is enabled
---@field canvas_dirty boolean Whether the canvas needs to be redrawn
---@field prev_player_pos pos The last position where the player was
local fog_of_war = {
    grid = {},
    size = pos.new(0, 0),
    inner_radius = 4,
    outer_radius = 7,
    canvas = nil,
    tile_size = 0,
    enabled = true,
    canvas_dirty = true,
    prev_player_pos = nil
}

---Initialize the fog of war grid
---@param opts? {reset: boolean, inner_radius: number?, outer_radius: number?} Configuration options
function fog_of_war.load(opts)
    opts = opts or { reset = true }
    
    if opts.reset then
        -- Get map dimensions from dungeon
        local map_width = DI.dungeon.map.width
        local map_height = DI.dungeon.map.height
        fog_of_war.tile_size = DI.dungeon.tile_size
        
        -- Initialize grid to all unexplored (0)
        fog_of_war.grid = {}
        for y = 1, map_height do
            fog_of_war.grid[y] = {}
            for x = 1, map_width do
                fog_of_war.grid[y][x] = 0
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
        
        -- Reset state
        fog_of_war.canvas_dirty = true
        fog_of_war.prev_player_pos = nil
        
        -- Register debug commands
        fow_debug.register_commands(fog_of_war)
        
        -- Immediately reveal the area around player
        local delayed_reveal = function()
            if DI.player and DI.player.pos then
                -- Make sure area around player is visible
                fog_of_war.reveal_around(DI.player.pos)
                fow_draw.update_canvas(fog_of_war)
                log.debug("Initial fog of war visibility set around player")
            else
                -- Try again in 0.2 seconds
                log.debug("Player not ready, will try fog reveal again in 0.2s")
                love.timer.after(0.2, delayed_reveal)
            end
        end
        
        -- Start the delayed reveal process
        delayed_reveal()
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
    
    -- Draw the fog of war
    fow_draw.draw(fog_of_war, translation_x, translation_y)
    
    -- Draw debug grid if enabled
    fow_debug.draw_grid(fog_of_war)
end

-- Function to toggle the debug grid
function fog_of_war.toggle_debug_grid()
    fow_debug.toggle_grid()
end

-- Register fog of war keyboard shortcuts
function fog_of_war.attach()
    fow_keys:attach()
end

-- Unregister fog of war keyboard shortcuts
function fog_of_war.detach()
    fow_keys:detach()
end

return fog_of_war 