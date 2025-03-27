local Vector2 = require("src.base.vector2")
local events = require("src.base.events")
local m = require("src.base.math")

---@class Player
---@field pos Vector2
---@field tile_id number
---@field tile table
---@field speed number
---@field hitpoints number
---@field max_hitpoints number
---@field weapon table
---@field shield table
---@field tile_size number
---@field last_direction Vector2
---@field cooldown number
---@field armorclass number
---@field is_dead boolean
---@field death_time number|nil Time remaining in death animation
local player = {
    pos = Vector2.new(0, 0),
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
    last_direction = Vector2.new(1, 0), -- Default facing right
    cooldown = 0,                       -- Initialize cooldown to 0
    armorclass = 0                      -- Base armor class
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
        _game.sound.play("player_hit", math.min(actual_damage / 20, 1))
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
        _game.pathfinder.clear()
        -- Play dramatic death sound
        _game.sound.play("player_death", 1.0)
    end
end

function player.load()
    local start = _game.dungeon.get_player_start_position()
    print("Player setup:", start)
    print("Player position:", start.pos)

    player.pos = start.pos
    player.tile = start.tile
    player.tile_id = start.tile.id

    local setup = _game.dungeon.player
    player.speed = setup.speed
    player.armorclass = setup.armorclass
    player.hitpoints = setup.hitpoints
    player.max_hitpoints = setup.max_hitpoints

    -- Get tile size from tileset
    player.tile_size = _game.dungeon.map.tilewidth

    -- Assign initial weapon
    for _, weapon in pairs(_game.dungeon.weapons) do
        if weapon.name == setup.weapon then
            player.weapon = weapon
            break
        end
    end

    -- Add player to global game variable
    _game.player = player
end

---@param movement Vector2 The normalized movement vector
---@param original_movement Vector2 The non-normalized movement vector for wall sliding
---@param dt number Delta time in seconds
function player.handle_movement(movement, original_movement, dt)
    -- Calculate new position
    local new_pos = player.pos + movement * (player.speed * dt)

    -- Try full movement first
    if _game.collision.is_walkable(new_pos.x, new_pos.y) then
        player.pos = new_pos
    else
        -- If full movement blocked, try sliding along walls using original (non-normalized) movement
        local slide_x = Vector2.new(player.pos.x + original_movement.x * (player.speed * dt), player.pos.y)
        local slide_y = Vector2.new(player.pos.x, player.pos.y + original_movement.y * (player.speed * dt))

        -- Try horizontal movement
        if original_movement.x ~= 0 and _game.collision.is_walkable(slide_x.x, slide_x.y) then
            player.pos = slide_x
            return
        end

        -- Try vertical movement
        if original_movement.y ~= 0 and _game.collision.is_walkable(slide_y.x, slide_y.y) then
            player.pos = slide_y
            return
        end
    end
end

---@return Vector2 The movement vector from keyboard input
function player.get_movement_input()
    ---@type Vector2
    local movement = Vector2.new(0, 0)
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
    local collected = _game.collectibles.check_collection(player.pos)
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
---@param current_tile Vector2 The current tile position
function player.check_tile_position_change(current_tile)
    -- Initialize last_tile if not set
    player.last_tile = player.last_tile or Vector2.new(-1, -1)

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
    local original_movement = Vector2.new(movement.x, movement.y)

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
    local current_tile = Vector2.new(
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
    local screen_x = math.floor((player.pos.x - 1) * _game.dungeon.map.tilewidth)
    local screen_y = math.floor((player.pos.y - 1) * _game.dungeon.map.tileheight)

    -- Get tile dimensions
    local _, _, tile_width, tile_height = player.tile.quad:getViewport()

    -- Calculate death animation scale
    local scale_y = 1
    if player.is_dead and player.death_time and player.death_time > 0 then
        scale_y = player.death_time / 0.5 -- Squeeze down over 0.5 seconds
    end

    -- Draw blood spots if dead
    if player.is_dead then
        -- Create random but consistent blood spots
        math.randomseed(screen_x * screen_y) -- Use position as seed for consistency

        -- Draw 5 blood spots with random properties
        for i = 1, 5 do
            -- Random dark red colors
            local red = 0.6 + math.random() * 0.3 -- Between 0.6 and 0.9
            local green = 0.0
            local blue = 0.0
            love.graphics.setColor(red, green, blue, 1)

            -- Random positions within a small area
            local offset_x = math.random(-8, 8)
            local offset_y = math.random(-8, 8)

            -- Random sizes
            local spot_radius = 2 + math.random() * 3 -- Between 2 and 5 pixels

            love.graphics.circle("fill",
                screen_x + offset_x,
                screen_y + offset_y,
                spot_radius
            )
        end

        love.graphics.setColor(1, 1, 1, 1) -- Reset color

        if not player.death_time or player.death_time <= 0 then
            return -- Don't draw player sprite if dead
        end
    end

    if player.tile and player.tile.quad then
        -- Draw sprite centered on player position
        love.graphics.draw(
            _game.dungeon.map.tilesets[1].image,
            player.tile.quad,
            screen_x,
            screen_y,
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
            _game.dungeon.map.tilesets[1].image,
            player.shield.tile.quad,
            screen_x - tile_width,
            screen_y - tile_height / 3
        )
    end

    -- Draw active weapon on top of player
    if player.weapon then
        -- Draw weapon centered on player position with rotation
        love.graphics.draw(
            _game.dungeon.map.tilesets[1].image,
            player.weapon.tile.quad,
            screen_x + tile_width / 2,
            screen_y - tile_height * 2 / 3,
            math.rad(45) -- 45 degree rotation
        )
    end
end

function player.draw_ui()
    local padding = 8                                -- Virtual pixels padding
    local box_padding = padding / 2                  -- Half padding for indicator boxes
    local bar_width = 50                             -- Width of health bars
    local bar_height = 4                             -- Height of health bars
    local bar_spacing = 4                            -- Space between bars
    local box_size = _game.dungeon.map.tilewidth -- Use tile size for indicator boxes

    -- Reset blend mode to default
    love.graphics.setBlendMode("alpha")

    -- Draw active weapon in UI with background box
    if player.weapon then
        -- Draw weapon box background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill",
            box_padding,
            _game.camera.height - box_size - box_padding,
            box_size,
            box_size
        )
        -- Draw weapon box border
        love.graphics.setColor(1, 1, 1, 1) -- Solid white border
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line",
            box_padding,
            _game.camera.height - box_size - box_padding,
            box_size,
            box_size
        )
        -- Draw weapon
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            _game.dungeon.map.tilesets[1].image,
            player.weapon.tile.quad,
            box_padding,
            _game.camera.height - box_size - box_padding
        )
    end

    -- Always draw shield box background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill",
        box_padding * 2 + box_size,
        _game.camera.height - box_size - box_padding,
        box_size,
        box_size
    )
    -- Draw shield box border
    love.graphics.setColor(1, 1, 1, 1) -- Solid white border
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line",
        box_padding * 2 + box_size,
        _game.camera.height - box_size - box_padding,
        box_size,
        box_size
    )
    -- Draw shield if player has one
    if player.shield then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            _game.dungeon.map.tilesets[1].image,
            player.shield.tile.quad,
            box_padding * 2 + box_size,
            _game.camera.height - box_size - box_padding
        )
    end

    -- Position for health bars (to the right of weapon/shield boxes)
    local bars_x = padding * 3 + box_size * 2
    local bars_y = _game.camera.height - bar_height - bar_spacing * 1.5 - padding

    -- Set line width for health bars
    love.graphics.setLineWidth(1)

    -- Draw player health bar
    local health_percent = player.hitpoints / player.max_hitpoints
    -- Draw dark border
    love.graphics.setColor(0.5, 0, 0, 1) -- Solid dark red border
    love.graphics.rectangle("line",
        bars_x,
        bars_y,
        bar_width,
        bar_height
    )
    -- Draw fill
    love.graphics.setColor(1, 0, 0, 1) -- Solid red
    love.graphics.rectangle("fill",
        bars_x,
        bars_y,
        bar_width * health_percent,
        bar_height
    )

    -- Draw shield health bar if player has a shield
    if player.shield then
        local shield_percent = player.shield.hitpoints / player.shield.max_hitpoints
        -- Draw dark border
        love.graphics.setColor(0, 0.5, 0, 1) -- Solid dark green border
        love.graphics.rectangle("line",
            bars_x,
            bars_y + bar_height + bar_spacing,
            bar_width,
            bar_height
        )
        -- Draw fill
        love.graphics.setColor(0, 1, 0, 1) -- Solid green
        love.graphics.rectangle("fill",
            bars_x,
            bars_y + bar_height + bar_spacing,
            bar_width * shield_percent,
            bar_height
        )
    end

    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

function player.update_pathfinder(current_tile)
    if not current_tile then return end

    -- Get map dimensions from dungeon
    local map_width = _game.dungeon.map.width
    local map_height = _game.dungeon.map.height

    -- Calculate Dijkstra distances from current tile position
    _game.pathfinder.calculate_dijkstra_distances(
        current_tile.x,
        current_tile.y,
        map_width,
        map_height
    )
end

return player
