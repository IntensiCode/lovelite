local projectiles = require("src.projectiles")

---@class Enemy
---@field pos pos
---@field weapon table
---@field cooldown number
---@field backoff number|nil

local combat = {}

---Initialize enemy combat state
---@param enemy Enemy The enemy to initialize
function combat.init(enemy)
    -- TODO: Apprentice
    if not enemy.weapon then
        table.print_deep("enemy", enemy)
        assert(enemy.weapon, "Enemy must have a weapon set")
    end
    enemy.cooldown = 0
end

---Try to attack player if in range
---@param enemy Enemy The enemy to update
function combat.try_attack_player(enemy)
    -- Don't attack dead players
    if DI.player.is_dead then
        return
    end

    local player_pos = DI.player.pos
    local distance_to_player = (player_pos - enemy.pos):length()

    -- Return early if player is out of range
    if distance_to_player > enemy.weapon.range then
        return
    end

    -- Return early if on cooldown
    if enemy.cooldown > 0 then
        return
    end

    if enemy.weapon.melee then
        -- Melee attack, deal damage to player and back off
        DI.player.on_hit(enemy.weapon)
        enemy.backoff = 1
    else
        -- Ranged attack, get direction to player and shoot projectile
        local dir = (player_pos - enemy.pos):normalized()
        print("Shooting projectile " .. enemy.weapon.name)
        projectiles.spawn({
            pos = enemy.pos,
            direction = dir,
            weapon = enemy.weapon,
            owner = "enemy"
        })
        enemy.backoff = 2
    end

    -- Reset cooldown
    enemy.cooldown = enemy.weapon.cooldown
end

---Update enemy combat state
---@param enemy Enemy The enemy to update
---@param dt number Delta time in seconds
function combat.update(enemy, dt)
    if not enemy.cooldown then
        combat.init(enemy)
    end

    -- Update cooldown
    if enemy.cooldown > 0 then
        enemy.cooldown = enemy.cooldown - dt
        return -- Don't move while on cooldown
    end

    combat.try_attack_player(enemy)
end

return combat
