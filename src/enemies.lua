local Vector2 = require("src.base.vector2")
local events = require("src.base.events")
local table_utils = require("src.base.table")
local m = require("src.base.math")
local bully = require("src.enemy.bully")
local backoff = require("src.enemy.backoff")

---@class Enemy
---@field pos Vector2
---@field tile table Reference to the tile from map_manager.tiles
---@field name string
---@field behavior string The enemy's behavior type (wizard, bully, etc.)
---@field hitpoints number The enemy's current health
---@field max_hitpoints number The enemy's maximum health
---@field is_dead boolean Whether the enemy is dead
---@field stun_time number Stun time in seconds
---@field backoff number|nil Time to back off after being hit
---@field backoff_tile Vector2|nil The tile to move to during backoff
---@field will_retreat boolean Whether the enemy will retreat when hit (default: true)
---@field jump_height number Current height of happy jump
---@field jump_time number Time elapsed in current jump
---@field next_jump_delay number Time until next jump starts
---@field jump_speed number Speed of the jump animation

local enemies = {
    items = {}
}

-- Jump animation constants
local JUMP_DURATION = 0.5
local JUMP_MAX_HEIGHT = 0.3 -- In tile units
local JUMP_SPEED = 2        -- Halved from 4

function enemies.load()
    -- Get the Objects layer
    local objects_layer = _game.map_manager.get_objects_layer()

    -- Process each tile in the Objects layer
    for y = 1, objects_layer.height do
        for x = 1, objects_layer.width do
            local tile = _game.map_manager.get_objects_tile(x, y)
            if tile and tile.properties and tile.properties["kind"] == "enemy" then
                local enemy_data = _game.map_manager.enemies[tile.gid]
                -- Clone the enemy data and add instance-specific properties
                local enemy = table_utils.clone(enemy_data)
                -- Add instance-specific properties
                enemy.pos = Vector2.new(x + 0.5, y + 0.5)
                enemy.tile = tile
                enemy.name = tile.properties["name"] or "Enemy"
                enemy.is_dead = false
                enemy.will_retreat = enemy_data.will_retreat ~= false -- Default to true unless explicitly set to false
                -- Initialize jump properties with random initial delay
                enemy.jump_height = 0
                enemy.jump_time = 0
                enemy.next_jump_delay = math.random() * 0.5 -- Initial delay still random 0-0.5
                enemy.jump_speed = JUMP_SPEED
                table.insert(enemies.items, enemy)
            end
        end
    end

    -- Debug print enemies
    print("\nEnemies loaded:")
    for i, enemy in ipairs(enemies.items) do
        print(string.format("  %d. %s at (%d, %d) with %d HP, AC %d, and resistances (F:%s I:%s L:%s)",
            i, enemy.behavior or "Unknown", enemy.pos.x, enemy.pos.y, enemy.hitpoints or 0, enemy.armorclass or 0,
            enemy.resistance_fire or "N/A", enemy.resistance_ice or "N/A", enemy.resistance_lightning or "N/A"))
    end
end

---Update enemy jump animation
---@param enemy Enemy The enemy to update
---@param dt number Delta time in seconds
local function update_happy_jump(enemy, dt)
    if enemy.next_jump_delay > 0 then
        enemy.next_jump_delay = enemy.next_jump_delay - dt
        return
    end

    enemy.jump_time = enemy.jump_time + dt * enemy.jump_speed

    -- Calculate jump height using sine wave
    enemy.jump_height = math.abs(math.sin(enemy.jump_time * math.pi * 2) * JUMP_MAX_HEIGHT)

    -- If we completed a jump, set up the next one with random delay between 1.0 and 2.0
    if enemy.jump_time >= 1 then
        enemy.jump_time = 0
        enemy.next_jump_delay = 1.0 + math.random() -- Random between 1.0 and 2.0
    end
end

function enemies.update(dt)
    -- Update enemies
    for i = #enemies.items, 1, -1 do
        local enemy = enemies.items[i]

        -- Check if enemy is dead
        if enemy.is_dead then
            -- Spawn dust particles
            events.send("particles.spawn", {
                pos = enemy.pos + Vector2.new(0.5, 0.5),
                kind = "dust"
            })

            -- Remove the enemy
            table.remove(enemies.items, i)

            goto continue
        end

        -- If player is dead, do happy jumps!
        if _game.player.is_dead then
            update_happy_jump(enemy, dt)
            goto continue
        end

        -- Handle stun time
        if enemy.stun_time and enemy.stun_time > 0 then
            enemy.stun_time = enemy.stun_time - dt
            if enemy.stun_time <= 0 then
                enemy.stun_time = nil
            end
            -- Spawn ice particles to indicate stun, randomly
            if math.random() < 0.025 then
                events.send("particles.spawn", {
                    pos = enemy.pos + Vector2.new(0.5, 0.5),
                    kind = "ice",
                    count = 1
                })
            end
            goto continue
        end

        -- Handle backoff behavior
        if enemy.backoff and enemy.backoff > 0 then
            backoff.update(enemy, dt)
            goto continue
        end

        -- Call enemy behavior based on type
        if enemy.behavior == "bully" then
            bully.update(enemy, dt)
        end

        ::continue::
    end
end

function enemies.draw()
    -- Helper function to check if an enemy overlaps with player
    local function is_overlapping_player(pos)
        return math.abs(pos.x - _game.player.pos.x) < 1 and 
               math.abs(pos.y - _game.player.pos.y) < 1
    end

    -- Store original graphics state
    local original_color = {love.graphics.getColor()}
    local original_blend_mode = love.graphics.getBlendMode()
    love.graphics.setBlendMode("alpha")

    for _, enemy in ipairs(enemies.items) do
        -- Convert tile position to screen position
        local tile_size = _game.map_manager.map.tilewidth
        local screen_x = (enemy.pos.x - 1) * tile_size
        local screen_y = (enemy.pos.y - 1) * tile_size

        -- Apply jump height offset
        screen_y = screen_y - (enemy.jump_height or 0) * tile_size

        -- Set color based on overlap and stun state
        if enemy.stun_time and enemy.stun_time > 0 then
            if is_overlapping_player(enemy.pos) then
                love.graphics.setColor(0.6, 0.6, 1.0, 0.75) -- Transparent blue tint
            else
                love.graphics.setColor(0.6, 0.6, 1.0, 1.0) -- Blue tint
            end
        else
            if is_overlapping_player(enemy.pos) then
                love.graphics.setColor(1, 1, 1, 0.75) -- Transparent
            else
                love.graphics.setColor(1, 1, 1, 1) -- Normal color
            end
        end

        -- Draw enemy centered
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            enemy.tile.quad,
            screen_x,
            screen_y,
            0,             -- rotation
            1,             -- scale x
            1,             -- scale y
            tile_size / 2, -- origin x (center of sprite)
            tile_size / 2  -- origin y (center of sprite)
        )

        -- Draw health bar if damaged
        if enemy.hitpoints < enemy.max_hitpoints then
            -- Health bar background
            love.graphics.setColor(0.5, 0, 0, 1)
            love.graphics.rectangle("fill", screen_x - tile_size/2, screen_y - tile_size/2 - 5, tile_size, 2)
            
            -- Health bar foreground
            love.graphics.setColor(0, 1, 0, 1)
            local health_width = (enemy.hitpoints / enemy.max_hitpoints) * tile_size
            love.graphics.rectangle("fill", screen_x - tile_size/2, screen_y - tile_size/2 - 5, health_width, 2)
        end
    end

    -- Restore original graphics state
    love.graphics.setColor(unpack(original_color))
    love.graphics.setBlendMode(original_blend_mode)
end

---@param pos Vector2 The position to check around
---@return Enemy[] Array of enemies within one tile distance
function enemies.find_enemies_close_to(pos)
    local nearby_enemies = {}
    local max_distance = 0.8

    -- Translate pos half tile to the left and up
    pos = pos - Vector2.new(0.5, 0.5)

    for _, enemy in ipairs(enemies.items) do
        if not enemy.is_dead then
            local distance = (enemy.pos - pos):length()
            if distance <= max_distance then
                table.insert(nearby_enemies, enemy)
            end
        end
    end

    return nearby_enemies
end

---@param enemy Enemy The enemy that was hit
---@param projectile table The projectile that hit the enemy
function enemies.on_hit(enemy, projectile)
    -- Set backoff state when hit by any projectile if the enemy will retreat
    if enemy.will_retreat then
        enemy.backoff = 0.5
    end

    if projectile.weapon.melee then
        -- Get armor class (default to 0 if nil) and clamp between 0 and 100
        local armor_class = enemy.armorclass or 0
        armor_class = m.clamp(armor_class, 0, 100)

        -- Calculate damage reduction based on armor class percentage
        local damage_reduction = projectile.weapon.melee * (armor_class / 100)
        local actual_damage = projectile.weapon.melee - damage_reduction

        enemy.hitpoints = enemy.hitpoints - actual_damage
        if enemy.hitpoints <= 0 then
            enemy.is_dead = true
        end
    elseif projectile.weapon.fire then
        -- Get fire resistance (default to 0 if nil) and clamp between 0 and 100
        local fire_resistance = enemy.resistance_fire or 0
        fire_resistance = m.clamp(fire_resistance, 0, 100)

        -- Calculate damage reduction based on fire resistance percentage
        local damage_reduction = projectile.weapon.fire * (fire_resistance / 100)
        local actual_damage = projectile.weapon.fire - damage_reduction

        enemy.hitpoints = enemy.hitpoints - actual_damage
        if enemy.hitpoints <= 0 then
            enemy.is_dead = true
        end
    elseif projectile.weapon.ice then
        -- Get ice resistance (default to 0 if nil) and clamp between 0 and 100
        local ice_resistance = enemy.resistance_ice or 0
        ice_resistance = m.clamp(ice_resistance, 0, 100)

        -- Calculate damage reduction based on ice resistance percentage
        local damage_reduction = projectile.weapon.ice * (ice_resistance / 100)
        local actual_damage = projectile.weapon.ice - damage_reduction

        enemy.hitpoints = enemy.hitpoints - actual_damage
        if enemy.hitpoints <= 0 then
            enemy.is_dead = true
        end

        -- Add stun time based on damage
        enemy.stun_time = (enemy.stun_time or 0) + (actual_damage / 10)
    elseif projectile.weapon.lightning then
        -- Get lightning resistance (default to 0 if nil) and clamp between 0 and 100
        local lightning_resistance = enemy.resistance_lightning or 0
        lightning_resistance = m.clamp(lightning_resistance, 0, 100)

        -- Calculate damage reduction based on lightning resistance percentage
        local damage_reduction = projectile.weapon.lightning * (lightning_resistance / 100)
        local actual_damage = projectile.weapon.lightning - damage_reduction

        enemy.hitpoints = enemy.hitpoints - actual_damage
        if enemy.hitpoints <= 0 then
            enemy.is_dead = true
        end
    end
end

-- Add enemies to global game variable when loaded
_game = _game or {}
_game.enemies = enemies

return enemies
