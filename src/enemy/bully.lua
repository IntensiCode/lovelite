local movement = require("src.enemy.behaviors.movement")
local combat = require("src.enemy.behaviors.combat")
local pathfinding = require("src.enemy.behaviors.pathfinding")

---@class Bully
---@field pos pos
---@field hitpoints number
---@field max_hitpoints number
---@field is_dead boolean
---@field stun_time number|nil
---@field speed number
---@field last_direction pos
---@field move_target pos|nil
---@field weapon table
---@field cooldown number

local bully = {}

function bully.init(enemy)
    combat.init(enemy)
end

---Update the bully's behavior
---@param enemy Bully The enemy to update
---@param dt number Delta time in seconds
function bully.update(enemy, dt)
    -- Update combat state
    combat.update(enemy, dt)

    -- If we're not on cooldown, update pathfinding and movement
    if enemy.cooldown <= 0 then
        pathfinding.update_target(enemy)
        if enemy.move_target then
            movement.move_towards_target(enemy, enemy.move_target, dt)
        end
    end
end

return bully
