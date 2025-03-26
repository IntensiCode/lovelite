local Vector2 = require("src.base.vector2")
local pathfinder = require("src.pathfinder")

---@class Bully
---@field pos Vector2
---@field hitpoints number
---@field max_hitpoints number
---@field is_dead boolean
---@field stun_time number|nil
---@field speed number
---@field last_direction Vector2
---@field move_target Vector2|nil

local bully = {}

---Update the bully's behavior
---@param enemy Bully The enemy to update
---@param dt number Delta time in seconds
function bully.update(enemy, dt)
    -- Find path from player to enemy (reverse Dijkstra)
    local path = pathfinder.find_path_to_start(
        math.floor(enemy.pos.x + 0.5),
        math.floor(enemy.pos.y + 0.5)
    )

    -- Set movement target based on path
    if path and #path > 1 and #path <= 10 then
        -- Get first position in path (closest to player)
        local target = path[2]
        enemy.move_target = Vector2.new(target.x, target.y)
    else
        enemy.move_target = nil
    end

    -- Move towards target if we have one
    if enemy.move_target then
        print("Moving from " .. enemy.pos.x .. ", " .. enemy.pos.y .. " to " .. enemy.move_target.x .. ", " .. enemy.move_target.y)
        local direction = enemy.move_target - enemy.pos
        local distance = direction:length()
        
        -- Normalize direction and apply speed
        if distance > 0 then
            direction = direction / distance
            print("Direction: " .. direction.x .. ", " .. direction.y)
            print("Distance: " .. distance)
            print("Speed: " .. enemy.speed)
            enemy.pos = enemy.pos + direction * enemy.speed * dt
        end
    end
end

return bully 