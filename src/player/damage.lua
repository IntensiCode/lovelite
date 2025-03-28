local damage = {}

function damage.on_hit(player, weapon)
    -- Don't take damage if already dead
    if player.is_dead then
        return
    end

    if weapon.melee then
        -- Get armor class (default to 0 if nil) and clamp between 0 and 100
        local armor_class = player.armorclass or 0
        armor_class = math.clamp(armor_class, 0, 100)

        -- Calculate damage reduction based on armor class percentage
        local damage_reduction = weapon.melee * (armor_class / 100)
        local actual_damage = weapon.melee - damage_reduction

        player.hitpoints = player.hitpoints - actual_damage

        -- Play hit sound with volume based on damage
        DI.sound.play("player_hit", math.min(actual_damage / 20, 1))

        -- Add small blood spots when hit
        DI.decals.spawn("blood", player.pos)
    elseif weapon.sonic or weapon.strongsonic then
        -- Sonic weapons apply damage over time
        -- Store the damage and duration in a table if not exists
        player.sonic_damage = player.sonic_damage or {}
        table.insert(player.sonic_damage, {
            damage = weapon.damage,
            time_left = 0.0
        })
        player.sonic_damage.damage = player.sonic_damage.damage + weapon.damage
        player.sonic_damage.time_left = player.sonic_damage.time_left + 2.0
    elseif weapon.damage then
        -- Direct damage weapons
        player.hitpoints = player.hitpoints - weapon.damage
    end

    -- Check if player is dead
    if player.hitpoints <= 0 then
        player.hitpoints = 0
        player.is_dead = true
        player.death_time = 0.5

        -- Clear pathfinding data when player dies
        DI.pathfinder.clear()

        -- Play dramatic death sound
        DI.sound.play("player_death", 1.0)

        -- Add blood pool when player dies
        DI.decals.spawn("blood_pool", player.pos)
    end
end

---Handle sonic damage over time
---@param player table The player object
---@param dt number Delta time in seconds
function damage.handle_sonic_damage(player, dt)
    if player.sonic_damage then
        player.sonic_damage.time_left = player.sonic_damage.time_left - dt
        if player.sonic_damage.time_left <= 0 then
            player.sonic_damage = nil
        else
            local amount = player.sonic_damage.damage * dt
            player.hitpoints = player.hitpoints - amount
        end
    end
end

return damage 