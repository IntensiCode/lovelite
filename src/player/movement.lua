local pos = require("src.base.pos")

local movement = {}

---@param player table The player object
---@param movement pos The normalized movement vector
---@param original_movement pos The non-normalized movement vector for wall sliding
---@param dt number Delta time in seconds
function movement.handle(player, movement, original_movement, dt)
    -- Calculate new position
    local new_pos = player.pos + movement * (player.speed * dt)

    -- Try full movement first
    if DI.collision.is_walkable(new_pos.x, new_pos.y) then
        player.pos = new_pos
    else
        -- If full movement blocked, try sliding along walls using original (non-normalized) movement
        local slide_x = pos.new(player.pos.x + original_movement.x * (player.speed * dt), player.pos.y)
        local slide_y = pos.new(player.pos.x, player.pos.y + original_movement.y * (player.speed * dt))

        -- Try horizontal movement
        if original_movement.x ~= 0 and DI.collision.is_walkable(slide_x.x, slide_x.y) then
            player.pos = slide_x
            return
        end

        -- Try vertical movement
        if original_movement.y ~= 0 and DI.collision.is_walkable(slide_y.x, slide_y.y) then
            player.pos = slide_y
            return
        end
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