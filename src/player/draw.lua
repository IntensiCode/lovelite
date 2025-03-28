local draw = {}

function draw.player(player)
    -- Convert tile position to screen position (snap to integer pixels)
    -- Subtract 1 from position to account for Lua's 1-based indexing
    local screen_pos = DI.dungeon.grid_to_screen(player.pos)

    -- Get tile dimensions
    local _, _, tile_width, tile_height = player.tile.quad:getViewport()

    -- Calculate death animation scale
    local scale_y = 1
    if player.is_dead and player.death_time and player.death_time > 0 then
        scale_y = player.death_time / 0.5 -- Squeeze down over 0.5 seconds
    end

    -- Draw blood spots if dead
    if player.is_dead then
        if not player.death_time or player.death_time <= 0 then
            return -- Don't draw player sprite if dead
        end
    end

    if player.tile and player.tile.quad then
        -- Draw sprite centered on player position
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            player.tile.quad,
            screen_pos.x,
            screen_pos.y,
            0,              -- rotation
            1,              -- scale x
            scale_y,        -- scale y (squeeze down when dead)
            tile_width / 2, -- origin x (center of sprite)
            tile_height / 2 -- origin y (center of sprite)
        )
    end

    -- Draw active shield on the left side of player
    if player.shield then
        -- Draw shield centered on player position with rotation
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            player.shield.tile.quad,
            screen_pos.x - tile_width,
            screen_pos.y - tile_height / 3
        )
    end

    -- Draw active weapon on top of player
    if player.weapon then
        -- Draw weapon centered on player position with rotation
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            player.weapon.tile.quad,
            screen_pos.x + tile_width / 2,
            screen_pos.y - tile_height * 2 / 3,
            math.rad(45) -- 45 degree rotation
        )
    end
end

return draw 