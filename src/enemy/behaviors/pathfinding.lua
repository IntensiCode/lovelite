local Vector2 = require("src.base.vector2")
local pathfinder = require("src.pathfinder")

---@class Enemy
---@field pos Vector2
---@field move_target Vector2|nil

local pathfinding = {}

---Find path to player and update enemy's move target
---@param enemy Enemy The enemy to update
function pathfinding.update_target(enemy)
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
end

return pathfinding 