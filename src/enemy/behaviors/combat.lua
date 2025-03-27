local pos = require("src.base.pos")
local events = require("src.base.events")
local weapons = require("src.enemy.weapons")

---@class Enemy
---@field pos pos
---@field weapon table
---@field cooldown number
---@field backoff number|nil

local combat = {}

---Initialize enemy combat state
---@param enemy Enemy The enemy to initialize
function combat.init(enemy)
    enemy.weapon = weapons.fist
    enemy.cooldown = 0
end

---Try to attack player if in range
---@param enemy Enemy The enemy to update
function combat.try_attack_player(enemy)
    -- Don't attack dead players
    if _game.player.is_dead then
        return
    end

    local player_pos = _game.player.pos
    local distance_to_player = (player_pos - enemy.pos):length()
    -- Attack range of 1.5 tiles
    if distance_to_player <= 0.9 then
        -- Only attack if weapon cooldown has elapsed
        if enemy.cooldown <= 0 then
            -- Spawn dust particles at attack location
            events.send("particles.spawn", {
                pos = _game.player.pos,  -- Position is already centered
                kind = "dust"
            })

            -- Deal damage to player
            _game.player.on_hit(enemy.weapon)

            -- Reset cooldown and start backoff period
            enemy.cooldown = enemy.weapon.cooldown
            enemy.backoff = 1
        end
    end
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
        return  -- Don't move while on cooldown
    end

    combat.try_attack_player(enemy)
end

return combat 