local movement = require("src.enemy.behaviors.movement")
local pathfinding = require("src.enemy.behaviors.pathfinding")
local combat = require("src.enemy.behaviors.combat")

local spider = {}

---@param enemy Enemy The enemy to update
---@param dt number Delta time in seconds
function spider.update(enemy, dt)
    -- Update combat behavior
    combat.update(enemy, dt)

    -- Update pathfinding and movement
    pathfinding.update_target(enemy)
    if enemy.move_target then
        movement.move_towards_target(enemy, enemy.move_target, dt)
    end
end

return spider