local Vector2 = require("src.vector2")
local events = require("src.events")

---@class Enemy
---@field pos Vector2
---@field tile table Reference to the tile from map_manager.tiles
---@field name string
---@field behavior string The enemy's behavior type (wizard, bully, etc.)
---@field hitpoints number The enemy's current health
---@field max_hitpoints number The enemy's maximum health
---@field is_dead boolean Whether the enemy is dead
local enemies = {
    items = {}
}

function enemies.load()
    -- Get the Objects layer
    local objects_layer = _game.map_manager.get_objects_layer()

    -- Process each tile in the Objects layer
    for y = 1, objects_layer.height do
        for x = 1, objects_layer.width do
            local tile = _game.map_manager.get_objects_tile(x, y)
            if tile and tile.properties and tile.properties["kind"] == "enemy" then
                local hitpoints = tile.properties["hitpoints"] or 50
                -- Create an enemy for this tile
                table.insert(enemies.items, {
                    pos = Vector2.new(x, y),
                    tile = tile, -- Store reference to the tile
                    name = tile.properties["name"] or "Enemy",
                    behavior = tile.properties["behavior"] or "unknown",
                    hitpoints = hitpoints,
                    max_hitpoints = hitpoints,
                    is_dead = false
                })
            end
        end
    end

    -- Debug print enemies
    print("\nEnemies loaded:")
    for i, enemy in ipairs(enemies.items) do
        print(string.format("  %d. %s at (%d, %d) with %d HP",
            i, enemy.behavior, enemy.pos.x, enemy.pos.y, enemy.hitpoints))
    end
end

function enemies.update(dt)
    -- Update enemies
    for i = #enemies.items, 1, -1 do
        local enemy = enemies.items[i]

        -- if enemy.stun_time and enemy.stun_time > 0 then
        --     enemy.stun_time = enemy.stun_time - dt
        --     if enemy.stun_time <= 0 then
        --         enemy.stun_time = nil
        --     end
        --     goto continue
        -- end

        -- Check if enemy is dead
        if enemy.is_dead then
            -- Spawn dust particles
            events.send("particles.spawn", {
                pos = enemy.pos + Vector2.new(0.5, 0.5),
                kind = "dust",
                direction = Vector2.new(0, -0.5) -- Upward direction
            })

            -- Remove the enemy
            table.remove(enemies.items, i)

            goto continue
        end

        -- TODO Call enemy behavior

        ::continue::
    end
end

function enemies.draw()
    for _, enemy in ipairs(enemies.items) do
        -- Convert tile position to screen position
        local screen_x = ((enemy.pos.x - 1) * _game.map_manager.map.tilewidth)
        local screen_y = ((enemy.pos.y - 1) * _game.map_manager.map.tileheight)

        -- If enemy is stunned, draw a bluish tint
        if enemy.stun_time and enemy.stun_time > 0 then
            -- Set tint alpha from 1 to 0 based on stun_time
            local tint_alpha = 1 - (enemy.stun_time / 1)
            love.graphics.setColor(0.5, 0.5, 1, tint_alpha)
        end

        -- Draw enemy centered
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            enemy.tile.quad,
            screen_x,
            screen_y,
            0,
            1, 1
        )

        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Add enemies to global game variable when loaded
_game = _game or {}
_game.enemies = enemies

return enemies
