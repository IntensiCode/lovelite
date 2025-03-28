local player_hud = {}

function player_hud.draw()
    local padding = 8                            -- Virtual pixels padding
    local box_padding = padding / 2              -- Half padding for indicator boxes
    local bar_width = 50                         -- Width of health bars
    local bar_height = 4                         -- Height of health bars
    local bar_spacing = 4                        -- Space between bars
    local box_size = DI.dungeon.tile_size     -- Use tile size for indicator boxes

    -- Reset blend mode to default
    love.graphics.setBlendMode("alpha")

    -- Draw active weapon in UI with background box
    if DI.player.weapon then
        -- Draw weapon box background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill",
            box_padding,
            DI.camera.height - box_size - box_padding,
            box_size,
            box_size
        )
        -- Draw weapon box border
        love.graphics.setColor(1, 1, 1, 1) -- Solid white border
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line",
            box_padding,
            DI.camera.height - box_size - box_padding,
            box_size,
            box_size
        )
        -- Draw weapon
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            DI.player.weapon.tile.quad,
            box_padding,
            DI.camera.height - box_size - box_padding
        )
    end

    -- Always draw shield box background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill",
        box_padding * 2 + box_size,
        DI.camera.height - box_size - box_padding,
        box_size,
        box_size
    )
    -- Draw shield box border
    love.graphics.setColor(1, 1, 1, 1) -- Solid white border
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line",
        box_padding * 2 + box_size,
        DI.camera.height - box_size - box_padding,
        box_size,
        box_size
    )
    -- Draw shield if player has one
    if DI.player.shield then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            DI.player.shield.tile.quad,
            box_padding * 2 + box_size,
            DI.camera.height - box_size - box_padding
        )
    end

    -- Position for health bars (to the right of weapon/shield boxes)
    local bars_x = padding * 3 + box_size * 2
    local bars_y = DI.camera.height - bar_height - bar_spacing * 1.5 - padding

    -- Set line width for health bars
    love.graphics.setLineWidth(1)

    -- Draw player health bar
    local health_percent = DI.player.hitpoints / DI.player.max_hitpoints
    -- Draw dark border
    love.graphics.setColor(0.5, 0, 0, 1) -- Solid dark red border
    love.graphics.rectangle("line",
        bars_x,
        bars_y,
        bar_width,
        bar_height
    )
    -- Draw fill
    love.graphics.setColor(1, 0, 0, 1) -- Solid red
    love.graphics.rectangle("fill",
        bars_x,
        bars_y,
        bar_width * health_percent,
        bar_height
    )

    -- Draw shield health bar if player has a shield
    if DI.player.shield then
        local shield_percent = DI.player.shield.hitpoints / DI.player.shield.max_hitpoints
        -- Draw dark border
        love.graphics.setColor(0, 0.5, 0, 1) -- Solid dark green border
        love.graphics.rectangle("line",
            bars_x,
            bars_y + bar_height + bar_spacing,
            bar_width,
            bar_height
        )
        -- Draw fill
        love.graphics.setColor(0, 1, 0, 1) -- Solid green
        love.graphics.rectangle("fill",
            bars_x,
            bars_y + bar_height + bar_spacing,
            bar_width * shield_percent,
            bar_height
        )
    end

    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return player_hud 