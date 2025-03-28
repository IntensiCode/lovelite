local pos = require("src.base.pos")
local m = require("src.base.math")

---@class WanderState
---@field direction pos Current movement direction
---@field sleep_time number|nil Time remaining in sleep state
---@field visited table<string,boolean> Recently visited positions
---@field visit_order string[] Order of visited position keys
---@field straight_steps number Number of steps taken in current direction
---@field tiles_walked number Total tiles walked since last sleep
---@field is_sleepy boolean Whether the spider is ready to sleep

local wander = {}

---Convert a position to a string key for visited tracking
---@param p pos The position to convert
---@return string key The string key for the position
local function pos_key(p)
    return string.format("%.0f,%.0f", m.round(p.x), m.round(p.y))
end

---Count number of non-walkable tiles around a position
---@param center pos The position to check around
---@return number count Number of blocked tiles
---@return table<string,boolean> blocked_dirs Directions that are blocked ("n","s","e","w")
local function count_blocked_tiles(center)
    local count = 0
    local blocked = {}
    local directions = {
        n = pos.new(0, -1),
        s = pos.new(0, 1),
        e = pos.new(1, 0),
        w = pos.new(-1, 0)
    }

    for dir_name, dir in pairs(directions) do
        local check_pos = center + dir
        if not DI.collision.is_walkable(check_pos.x, check_pos.y) then
            count = count + 1
            blocked[dir_name] = true
        end
    end

    return count, blocked
end

---Get available movement directions from current position
---@param center pos The current position
---@param visited table<string,boolean> Recently visited positions
---@return pos[] directions Array of possible movement directions
local function get_available_directions(center, visited)
    local directions = {}
    local possible = {
        pos.new(0, -1), -- North
        pos.new(0, 1),  -- South
        pos.new(1, 0),  -- East
        pos.new(-1, 0)  -- West
    }

    for _, dir in ipairs(possible) do
        local check_pos = center + dir
        if DI.collision.is_walkable(check_pos.x, check_pos.y) and not visited[pos_key(check_pos)] then
            table.insert(directions, dir)
        end
    end

    -- If no unvisited directions available, allow any walkable direction
    if #directions == 0 then
        for _, dir in ipairs(possible) do
            local check_pos = center + dir
            if DI.collision.is_walkable(check_pos.x, check_pos.y) then
                table.insert(directions, dir)
            end
        end
    end

    return directions
end

---Update sleep state
---@param state WanderState The wander state
---@param enemy Enemy The enemy to update
---@param dt number Delta time in seconds
local function update_sleep_state(state, enemy, dt)
    state.sleep_time = state.sleep_time - dt
    if state.sleep_time <= 0 then
        state.sleep_time = nil
        -- Pick new direction after waking up
        local directions = get_available_directions(enemy.pos, state.visited)
        state.direction = directions[math.random(#directions)]
    end
end

---Get perpendicular directions to current direction
---@param current_dir pos Current direction vector
---@return pos[] directions Array of left and right turn directions
local function get_turn_directions(current_dir)
    -- For (0,1) return (-1,0) and (1,0)
    -- For (1,0) return (0,-1) and (0,1)
    return {
        pos.new(-current_dir.y, current_dir.x), -- Left turn
        pos.new(current_dir.y, -current_dir.x)  -- Right turn
    }
end

---Try to turn 90 degrees, or continue straight if turns are blocked
---@param enemy Enemy The enemy to update
---@param state WanderState The wander state
local function try_turn(enemy, state)
    local turn_dirs = get_turn_directions(state.direction)
    local available_turns = {}

    -- Check which turns are possible
    for _, dir in ipairs(turn_dirs) do
        local check_pos = enemy.pos + dir
        if DI.collision.is_walkable(check_pos.x, check_pos.y) then
            table.insert(available_turns, dir)
        end
    end

    -- If any turns are available, pick one randomly
    if #available_turns > 0 then
        state.direction = available_turns[math.random(#available_turns)]
        state.straight_steps = 0
    end
    -- If no turns available, continue straight (handled by not changing direction)
end

local function update_visited_positions(enemy, position, state)
    enemy.pos = position

    -- Move and update visited positions
    local key = pos_key(position)

    -- Add to visited positions and track order
    if not state.visited[key] then
        state.visited[key] = true
        table.insert(state.visit_order, key)
        
        -- Count steps in straight line and total tiles walked
        state.straight_steps = state.straight_steps + 1
        state.tiles_walked = state.tiles_walked + 1
        
        -- Get sleepy after walking enough tiles
        if state.tiles_walked >= 10 then
            state.is_sleepy = true
        end

        -- Keep only last 2 visited positions
        if #state.visit_order > 2 then
            local old_key = table.remove(state.visit_order, 1)
            state.visited[old_key] = nil
        end
        
        -- Try to turn after walking straight for too long
        if state.straight_steps >= 7 then
            try_turn(enemy, state)
        end
    end
end

---Initialize wander state
---@param enemy Enemy The enemy to initialize wandering for
function wander.init(enemy)
    -- Pick initial random direction
    local directions = get_available_directions(enemy.pos, {})
    local initial_dir = directions[math.random(#directions)]
    
    enemy.wander_state = {
        direction = initial_dir,
        sleep_time = nil,
        visited = {},
        visit_order = {},
        straight_steps = 0,
        tiles_walked = 0,
        is_sleepy = false
    }
end

---Check if enemy is currently in wandering state
---@param enemy Enemy The enemy to check
---@return boolean is_wandering True if enemy should continue wandering
function wander.is_wandering(enemy)
    -- Check if player is in range
    local distance_to_player = (DI.player.pos - enemy.pos):length()
    return distance_to_player > 5
end

---Handle sleep or direction change when movement is blocked
---@param enemy Enemy The enemy to handle
---@param state WanderState The wander state
local function sleep_or_change_direction(enemy, state)
    -- Check if in a corner
    local blocked_count = count_blocked_tiles(enemy.pos)
    if blocked_count >= 2 and state.is_sleepy then
        -- Found a corner and spider is sleepy, start sleeping
        state.sleep_time = 10.0
        state.straight_steps = 0
        state.tiles_walked = 0
        state.is_sleepy = false
    else
        -- Pick new direction, avoiding recently visited tiles if possible
        local directions = get_available_directions(enemy.pos, state.visited)
        state.direction = directions[math.random(#directions)]
        state.straight_steps = 0
    end
end

---Update enemy wandering behavior
---@param enemy Enemy The enemy to update
---@param dt number Delta time in seconds
function wander.update(enemy, dt)
    -- Initialize state if needed
    if not enemy.wander_state then
        wander.init(enemy)
    end

    local state = enemy.wander_state

    -- Update sleep state if sleeping
    if state.sleep_time then
        update_sleep_state(state, enemy, dt)
        return
    end

    -- Try to move in current direction
    local new_pos = enemy.pos + state.direction * enemy.speed * dt
    local walkable = DI.collision.is_walkable(new_pos.x, new_pos.y)
    if walkable then
        update_visited_positions(enemy, new_pos, state)
    else
        sleep_or_change_direction(enemy, state)
    end
end

return wander
