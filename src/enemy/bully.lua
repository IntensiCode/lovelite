local Vector2    = require("src.base.vector2")
local pathfinder = require("src.pathfinder")
local weapons    = require("src.enemy.weapons")
local events     = require("src.base.events")
local backoff    = require("src.enemy.backoff")

---@class Bully
---@field pos Vector2
---@field hitpoints number
---@field max_hitpoints number
---@field is_dead boolean
---@field stun_time number|nil
---@field speed number
---@field last_direction Vector2
---@field move_target Vector2|nil
---@field weapon table
---@field cooldown number
---@field backoff number|nil Time to back off after attacking
---@field backoff_tile Vector2|nil The tile to move to during backoff

local bully      = {}

function bully.init(enemy)
    enemy.weapon = weapons.fist
    enemy.cooldown = 0
    enemy.backoff = nil
    enemy.backoff_tile = nil
end

---Update the bully's behavior
---@param enemy Bully The enemy to update
---@param dt number Delta time in seconds
function bully.update(enemy, dt)
    if not enemy.cooldown then
        bully.init(enemy)
    end

    -- Handle backoff period
    if backoff.is_still_backing_off(enemy) then
        backoff.update(enemy, dt)
        -- Skip normal movement and attack logic during backoff
        return
    end

    -- Update cooldown
    if enemy.cooldown > 0 then
        enemy.cooldown = enemy.cooldown - dt
        return  -- Don't move while on cooldown
    end

    -- Only find path and move if not on cooldown
    -- Find path from player to enemy (reverse Dijkstra)
    local path = pathfinder.find_path_to_start(
        math.floor(enemy.pos.x),
        math.floor(enemy.pos.y)
    )

    -- Set movement target based on path
    if path and #path > 1 and #path <= 10 then
        -- Get first position in path (closest to player)
        local target = path[2]
        enemy.move_target = Vector2.new(target.x + 0.5, target.y + 0.5)  -- Add 0.5 to target to center it
    else
        enemy.move_target = nil
    end

    bully.move_towards_target(enemy, dt)
    bully.try_attack_player(enemy)
end

function bully.move_towards_target(enemy, dt)
    if enemy.move_target then
        local direction = enemy.move_target - enemy.pos
        local distance = direction:length()

        -- Normalize direction and apply speed
        if distance > 0 then
            direction = direction / distance
            enemy.pos = enemy.pos + direction * enemy.speed * dt
        end
    end
end

-- Try to attack player if in range
function bully.try_attack_player(enemy)
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

return bully
