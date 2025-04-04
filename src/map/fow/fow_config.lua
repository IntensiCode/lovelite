-- Fog of War Configuration Module
-- Centralizes configuration settings for the fog of war system

local pos = require("src.base.pos")

---@class FowConfig
---@field grid number[][] Grid tracking tile visibility: 0=unseen, 1=edge/heavy dither, 2=medium dither, 3=light dither, 4=visible
---@field memory_grid number[][] Grid tracking maximum visibility each tile has achieved
---@field size pos The size of the grid in tiles
---@field inner_radius number Radius of full visibility around player (in tiles)
---@field outer_radius number Radius of partial visibility around player (in tiles)
---@field tile_size number Size of a tile in pixels
---@field enabled boolean Whether fog of war is enabled
---@field field_of_view_mode boolean Whether field of view mode is enabled (areas outside view are darkened)
---@field hide_rooftops boolean Whether rooftops should be hidden with medium fog
---@field prev_player_pos pos The last position where the player was
local fow_config = {
    grid = {},
    memory_grid = {},
    size = pos.new(0, 0),
    inner_radius = 4,
    outer_radius = 8, -- Increased to accommodate more fog levels
    tile_size = 0,
    enabled = true,
    field_of_view_mode = true, -- Default to field of view mode
    hide_rooftops = true, -- Default to hiding rooftops
    prev_player_pos = nil
}

return fow_config 