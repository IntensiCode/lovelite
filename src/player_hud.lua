local pos = require "src.base.pos"
local lg = require "src.base.lg"

local player_hud = {
    padding = 8,                            -- Virtual pixels padding
    box_padding = 4,                        -- Half padding for indicator boxes
    bar_width = 50,                         -- Width of health bars
    bar_height = 4,                         -- Height of health bars
    bar_spacing = 4,                        -- Space between bars
}

---Draw an indicator box with optional tile
---@param pos pos Position to draw at
---@param tile table|nil Tile to draw (optional)
function player_hud.draw_indicator(pos, tile)
    -- Draw box background
    lg.setColor(0, 0, 0, 0.7)
    lg.fillRect(pos, player_hud.box_size)
    -- Draw box border
    lg.setColor(1, 1, 1, 1) -- Solid white border
    lg.setLineWidth(1)
    lg.outlineRect(pos, player_hud.box_size)
    -- Draw tile if provided
    if tile then
        lg.setColor(1, 1, 1, 1)
        lg.draw(
            DI.dungeon.map.tilesets[1].image,
            tile.quad,
            pos.x,
            pos.y
        )
    end
end

---Draw a health bar
---@param pos pos Position to draw at
---@param current number Current value
---@param max number Maximum value
---@param color table Color for the bar {r, g, b}
function player_hud.draw_health_bar(pos, current, max, color)
    local percent = current / max
    -- Draw dark border
    lg.setColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, 1)
    lg.outlineRect(pos, player_hud.bar_width, player_hud.bar_height)
    -- Draw fill
    lg.setColor(color[1], color[2], color[3], 1)
    lg.fillRect(pos, player_hud.bar_width * percent, player_hud.bar_height)
end

function player_hud.draw()
    player_hud.box_size = DI.dungeon.tile_size       -- Use tile size for indicator boxes

    -- Reset blend mode to default
    lg.setBlendMode("alpha")

    -- Draw weapon and shield indicators
    local weapon_pos = pos.new(
        player_hud.box_padding,
        DI.camera.height - player_hud.box_size - player_hud.box_padding
    )
    local shield_pos = pos.new(
        player_hud.box_padding * 2 + player_hud.box_size,
        DI.camera.height - player_hud.box_size - player_hud.box_padding
    )

    player_hud.draw_indicator(weapon_pos, DI.player.weapon and DI.player.weapon.tile)
    player_hud.draw_indicator(shield_pos, DI.player.shield and DI.player.shield.tile)

    -- Position for health bars (to the right of weapon/shield boxes)
    local bars_x = player_hud.padding * 3 + player_hud.box_size * 2
    local bars_y = DI.camera.height - player_hud.bar_height - player_hud.bar_spacing * 1.5 - player_hud.padding

    -- Set line width for health bars
    lg.setLineWidth(1)

    -- Draw player health bar
    player_hud.draw_health_bar(
        pos.new(bars_x, bars_y),
        DI.player.hitpoints,
        DI.player.max_hitpoints,
        {1, 0, 0} -- Red
    )

    -- Draw shield health bar if player has a shield
    if DI.player.shield then
        player_hud.draw_health_bar(
            pos.new(bars_x, bars_y + player_hud.bar_height + player_hud.bar_spacing),
            DI.player.shield.hitpoints,
            DI.player.shield.max_hitpoints,
            {0, 1, 0} -- Green
        )
    end

    -- Reset color and line width
    lg.setColor(1, 1, 1, 1)
    lg.setLineWidth(1)
end

return player_hud 