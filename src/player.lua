local pos = require("src.base.pos")
local events = require("src.base.events")
local m = require("src.base.math")

---@class Player
---@field pos pos
---@field tile_id number
---@field tile table
---@field speed number
---@field hitpoints number
---@field max_hitpoints number
---@field weapon table
---@field shield table
---@field tile_size number
---@field last_direction pos
---@field cooldown number
---@field armorclass number
---@field is_dead boolean
---@field death_time number|nil Time remaining in death animation
local player = {
    pos = pos.new(0, 0),
    tile_id = nil,
    tile = nil,
    speed = 5, -- tiles per second
    hitpoints = 100,
    max_hitpoints = 100,
    is_dead = false,
    death_time = nil,
    weapon = nil,
    shield = nil,
    tile_size = nil,
    last_direction = pos.new(1, 0), -- Default facing right
    cooldown = 0,                   -- Initialize cooldown to 0
    armorclass = 0                  -- Base armor class
}

function player.on_hit(weapon)
    -- Don't take damage if already dead
    if player.is_dead then
        return
    end

    if weapon.melee then
        -- Get armor class (default to 0 if nil) and clamp between 0 and 100
        local armor_class = player.armorclass or 0
        armor_class = m.clamp(armor_class, 0, 100)

        -- Calculate damage reduction based on armor class percentage
        local damage_reduction = weapon.melee * (armor_class / 100)
        local actual_damage = weapon.melee - damage_reduction

        player.hitpoints = player.hitpoints - actual_damage

        -- Play hit sound with volume based on damage
        DI.sound.play("player_hit", math.min(actual_damage / 20, 1))

        -- Add small blood spots when hit
        DI.decals.spawn("blood", player.pos)
    elseif weapon.sonic or weapon.strongsonic then
        -- Sonic weapons apply damage over time
        -- Store the damage and duration in a table if not exists
        player.sonic_damage = player.sonic_damage or {}
        table.insert(player.sonic_damage, {
            damage = weapon.damage,
            time_left = 0.0
        })
        player.sonic_damage.damage = player.sonic_damage.damage + weapon.damage
        player.sonic_damage.time_left = player.sonic_damage.time_left + 2.0
    elseif weapon.damage then
        -- Direct damage weapons
        player.hitpoints = player.hitpoints - weapon.damage
    end

    -- Check if player is dead
    if player.hitpoints <= 0 then
        player.hitpoints = 0
        player.is_dead = true
        player.death_time = 0.5

        -- Clear pathfinding data when player dies
        DI.pathfinder.clear()

        -- Play dramatic death sound
        DI.sound.play("player_death", 1.0)

        -- Add blood pool when player dies
        DI.decals.spawn("blood_pool", player.pos)
    end
end

---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function player.load(opts)
    opts = opts or { reset = true }

    if opts.reset then
        -- Reset all player state
        local start = DI.dungeon.get_player_start_position()
        print("Player setup:", start)
        print("Player position:", start.pos)

        player.pos = start.pos
        player.tile = start.tile
        player.tile_id = start.tile.id

        local setup = DI.dungeon.player
        player.speed = setup.speed
        player.armorclass = setup.armorclass
        -- Set lower hitpoints in debug mode
        if DI.debug.enabled then
            player.hitpoints = 5
        else
            player.hitpoints = setup.hitpoints
        end
        player.max_hitpoints = setup.max_hitpoints

        -- Reset combat state
        player.is_dead = false
        player.death_time = nil
        player.cooldown = 0
        player.sonic_damage = nil
        player.last_tile = nil
        player.last_direction = pos.new(1, 0) -- Default facing right

        -- Reset equipment
        player.weapon = nil
        player.shield = nil

        -- Assign initial weapon if specified in dungeon setup
        if setup.weapon then
            for _, weapon in pairs(DI.dungeon.weapons) do
                if weapon.name == setup.weapon then
                    player.weapon = weapon
                    break
                end
            end
        end
    end

    -- Get tile size from tileset (this is constant and only needs to be set once)
    player.tile_size = DI.dungeon.tile_size

    -- Add player to global game variable
    DI.player = player
end

---@param movement pos The normalized movement vector
---@param original_movement pos The non-normalized movement vector for wall sliding
---@param dt number Delta time in seconds
function player.handle_movement(movement, original_movement, dt)
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
function player.get_movement_input()
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

---@param dt number Delta time in seconds
function player.handle_shooting()
    local shoot = love.keyboard.isDown("space") or love.keyboard.isDown("z")
        or love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

    if not shoot or not player.weapon then
        return
    end

    -- Check if weapon is on cooldown
    if player.cooldown > 0 then
        return
    end

    -- Set cooldown and spawn projectile via event
    player.cooldown = player.weapon.cooldown
    events.send("projectile.spawn", {
        pos = player.pos,
        direction = player.last_direction,
        weapon = player.weapon
    })
end

---Handle collection of items (weapons, shields, etc.)
function player.handle_collection()
    local collected = DI.collectibles.check_collection(player.pos)
    if not collected then
        return
    elseif collected.weapon then
        -- Store reference to the collected weapon
        player.weapon = collected.weapon
        -- Reset cooldown when switching weapons
        player.cooldown = 0
    elseif collected.shield then
        -- Store reference to the collected shield
        player.shield = collected.shield
    end
end

---Check if player's tile position has changed and update pathfinding if needed
---@param current_tile pos The current tile position
function player.check_tile_position_change(current_tile)
    -- Initialize last_tile if not set
    player.last_tile = player.last_tile or pos.new(-1, -1)

    -- Check if tile position changed
    if current_tile.x ~= player.last_tile.x or current_tile.y ~= player.last_tile.y then
        -- Update pathfinding data
        player.update_pathfinder(current_tile)
        -- Store new position
        player.last_tile = current_tile
    end
end

---Handle sonic damage over time
---@param dt number Delta time in seconds
function player.handle_sonic_damage(dt)
    if player.sonic_damage then
        player.sonic_damage.time_left = player.sonic_damage.time_left - dt
        if player.sonic_damage.time_left <= 0 then
            player.sonic_damage = nil
        else
            local amount = player.sonic_damage.damage * dt
            player.hitpoints = player.hitpoints - amount
        end
    end
end

function player.update(dt)
    -- Handle death animation
    if player.is_dead then
        if player.death_time and player.death_time > 0 then
            player.death_time = player.death_time - dt
        end
        return
    end

    -- Get movement input
    local movement = player.get_movement_input()

    -- Update last direction if moving
    if movement.x ~= 0 or movement.y ~= 0 then
        player.last_direction = movement:normalized()
    end

    -- Store original movement for wall sliding
    local original_movement = pos.new(movement.x, movement.y)

    -- Normalize diagonal movement for the initial movement attempt
    if movement.x ~= 0 and movement.y ~= 0 then
        movement = movement * 0.7071 -- 1/sqrt(2), maintains consistent speed diagonally
    end

    -- Handle movement
    player.handle_movement(movement, original_movement, dt)

    -- Update cooldown
    if player.cooldown > 0 then
        player.cooldown = player.cooldown - dt
    end

    -- Handle shooting
    player.handle_shooting()

    -- Check for collectibles
    player.handle_collection()

    -- Get current tile position (floored)
    local current_tile = pos.new(
        math.floor(player.pos.x),
        math.floor(player.pos.y)
    )

    -- Check tile position changes
    player.check_tile_position_change(current_tile)

    -- Handle sonic damage
    player.handle_sonic_damage(dt)
end

function player.draw()
    -- Convert tile position to screen position (snap to integer pixels)
    -- Subtract 1 from position to account for Lua's 1-based indexing
    local screen_pos = DI.dungeon.grid_to_screen(player.pos)

    -- Get tile dimensions
    local _, _, tile_width, tile_height = player.tile.quad:getViewport()

    -- Calculate death animation scale
    local scale_y = 1
    if player.is_dead and player.death_time and player.death_time > 0 then
        scale_y = player.death_time / 0.5 -- Squeeze down over 0.5 seconds
    end

    -- Draw blood spots if dead
    if player.is_dead then
        -- DI.decals.spawn("blood", pos.new(screen_x, screen_y))

        if not player.death_time or player.death_time <= 0 then
            return -- Don't draw player sprite if dead
        end
    end

    if player.tile and player.tile.quad then
        -- Draw sprite centered on player position
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            player.tile.quad,
            screen_pos.x,
            screen_pos.y,
            0,              -- rotation
            1,              -- scale x
            scale_y,        -- scale y (squeeze down when dead)
            tile_width / 2, -- origin x (center of sprite)
            tile_height / 2 -- origin y (center of sprite)
        )
    end

    -- Draw active shield on the left side of player
    if player.shield then
        -- Draw shield centered on player position with rotation
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            player.shield.tile.quad,
            screen_pos.x - tile_width,
            screen_pos.y - tile_height / 3
        )
    end

    -- Draw active weapon on top of player
    if player.weapon then
        -- Draw weapon centered on player position with rotation
        love.graphics.draw(
            DI.dungeon.map.tilesets[1].image,
            player.weapon.tile.quad,
            screen_pos.x + tile_width / 2,
            screen_pos.y - tile_height * 2 / 3,
            math.rad(45) -- 45 degree rotation
        )
    end
end

function player.update_pathfinder(current_tile)
    if not current_tile then return end

    -- Get map dimensions from dungeon
    local map_width = DI.dungeon.map.width
    local map_height = DI.dungeon.map.height

    -- Calculate Dijkstra distances from current tile position
    DI.pathfinder.calculate_dijkstra_distances(
        current_tile.x,
        current_tile.y,
        map_width,
        map_height
    )
end

return player
