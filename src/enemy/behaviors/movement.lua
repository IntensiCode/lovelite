---@class Enemy
---@field pos pos
---@field speed number
---@field move_target pos|nil

local movement = {}

---Try to slide along walls when movement is blocked
---@param pos pos Current position
---@param direction pos Movement direction
---@param speed number Movement speed
---@param dt number Delta time
---@return pos|nil New position if slide successful, nil otherwise
local function try_slide_movement(pos, direction, speed, dt)
    -- Try moving horizontally
    local horizontal_pos = pos.new(
        pos.x + direction.x * speed * dt,
        pos.y
    )
    if direction.x ~= 0 and DI.collision.is_walkable({
        x = horizontal_pos.x,
        y = horizontal_pos.y
    }) then
        return horizontal_pos
    end

    -- Try moving vertically
    local vertical_pos = pos.new(
        pos.x,
        pos.y + direction.y * speed * dt
    )
    if direction.y ~= 0 and DI.collision.is_walkable({
        x = vertical_pos.x,
        y = vertical_pos.y
    }) then
        return vertical_pos
    end

    return nil
end

---Move enemy towards a target position
---@param enemy Enemy The enemy to move
---@param target pos The target position
---@param dt number Delta time in seconds
function movement.move_towards_target(enemy, target, dt)
    local direction = target - enemy.pos
    local distance = direction:length()

    -- Only try to move if we're not already at the target
    if distance > 0.1 then
        -- Normalize direction
        direction = direction / distance

        -- Try full movement first
        local new_pos = enemy.pos + direction * enemy.speed * dt
        if DI.collision.is_walkable({
            x = new_pos.x,
            y = new_pos.y
        }) and not DI.collision.is_blocked_by_entity({
            x = new_pos.x,
            y = new_pos.y,
            exclude_id = enemy.id,
            min_distance = 0.9
        }) then
            enemy.pos = new_pos
            return true
        else
            -- If full movement blocked, try sliding along walls
            local slide_pos = try_slide_movement(enemy.pos, direction, enemy.speed, dt)
            if slide_pos and not DI.collision.is_blocked_by_entity({
                x = slide_pos.x,
                y = slide_pos.y,
                exclude_id = enemy.id,
                min_distance = 0.9
            }) then
                enemy.pos = slide_pos
                return true
            end
        end
    end
    return false
end

---Update happy jump movement for enemies when player is dead
---@param enemy Enemy The enemy to update
---@param dt number Delta time in seconds
function movement.update_happy_jump(enemy, dt)
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

return movement 