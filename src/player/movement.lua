local pos = require("src.base.pos")

local movement = {}

---Check if a position is walkable and not blocked by entities
---@param pos pos Position to check
---@return boolean walkable Whether the position is walkable and not blocked
local function can_walk_to(pos)
    return DI.collision.is_walkable({
        x = pos.x,
        y = pos.y
    }) and not DI.collision.is_blocked_by_entity({
        x = pos.x,
        y = pos.y,
        exclude_id = "player",
        min_distance = 0.9
    })
end

---Check if a position is walkable for the player
---@param pos pos Position to check
---@return boolean walkable Whether the position is walkable
local function is_position_walkable_for_player(pos)
    return DI.collision.is_walkable({
        x = pos.x,
        y = pos.y
    })
end

---Try to move towards a target position
---@param current_pos pos Current position
---@param target_pos pos Target position to move towards
---@param speed number Movement speed
---@param dt number Delta time
---@return boolean success Whether movement was successful
---@return pos|nil new_pos New position if movement was successful, otherwise nil
local function try_move_towards(current_pos, target_pos, speed, dt)
    local move_dir = target_pos - current_pos
    local distance = move_dir:length()
    if distance > 0.1 then
        move_dir = move_dir / distance
        local new_pos = current_pos + move_dir * speed * dt
        if can_walk_to(new_pos) then
            return true, new_pos
        end
    end
    return false, nil
end

---Try to slide around entities
---@param player table The player object
---@param target_pos pos The target position
---@param move_dir pos The normalized movement direction
---@param speed number The movement speed
---@param dt number Delta time in seconds
---@return boolean success Whether sliding was successful
local function try_slide_around_entities(player, target_pos, move_dir, speed, dt)
    local slide_opts = {
        from = player.pos,
        to = target_pos,
        move_dir = move_dir,
        exclude_id = "player",
        min_distance = 0.9
    }
    local slide_pos = DI.collision.find_entity_slide(slide_opts)
    if slide_pos then
        local success, new_pos = try_move_towards(player.pos, slide_pos, speed, dt)
        if success then
            player.pos = new_pos
            return true
        end
    end
    return false
end

---Handle player movement with entity collision and sliding
---@param player table The player object
---@param input pos The input movement vector
---@param dt number Delta time in seconds
function movement.handle(player, input, dt)
    if input.x == 0 and input.y == 0 then return end

    local move_dir = input:normalized()
    local speed = player.speed
    if player.slow_time and player.slow_time > 0 then
        speed = speed * player.slow_factor
    end

    local target_pos = player.pos + move_dir * speed * dt

    -- Try direct movement first
    if can_walk_to(target_pos) then
        player.pos = target_pos
    else
        -- Try sliding around entities
        try_slide_around_entities(player, target_pos, move_dir, speed, dt)
    end
end

---@return pos The movement vector from keyboard input
function movement.get_input()
    ---@type pos
    local movement = pos.new(0, 0)
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        movement.x = movement.x - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        movement.x = movement.x + 1
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        movement.y = movement.y - 1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        movement.y = movement.y + 1
    end
    return movement
end

return movement
