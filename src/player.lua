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
local player = {
    pos = Vector2.new(0, 0),
    tile_id = nil,
    tile = nil,
    speed = 5, -- tiles per second
    hitpoints = 100,
    max_hitpoints = 100,
    is_dead = false,
    armorclass = 0,
    weapon = nil,
    shield = nil,
    tile_size = nil,
    last_direction = Vector2.new(1, 0), -- Default facing right
    cooldown = 0,                       -- Initialize cooldown to 0
    armorclass = 0                      -- Base armor class
}

function player.on_hit(weapon)
    if weapon.melee then
        -- Get armor class (default to 0 if nil) and clamp between 0 and 100
        local armor_class = player.armorclass or 0
        armor_class = m.clamp(armor_class, 0, 100)

        -- Calculate damage reduction based on armor class percentage
        local damage_reduction = weapon.melee * (armor_class / 100)
        local actual_damage = weapon.melee - damage_reduction

        player.hitpoints = player.hitpoints - actual_damage
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
    end
end

function player.load()
    local start = _game.map_manager.get_player_start_position()
    print("Player setup:", start)
    print("Player position:", start.pos)

    player.pos = start.pos
    player.tile = start.tile
    player.tile_id = start.tile.id

    local setup = _game.map_manager.player
    player.speed = setup.speed
    player.armorclass = setup.armorclass
    player.hitpoints = setup.hitpoints
    player.max_hitpoints = setup.max_hitpoints

    -- Get tile size from tileset
    player.tile_size = _game.map_manager.map.tilewidth

    -- Assign initial weapon
    for gid, weapon in pairs(_game.map_manager.weapons) do
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
    if _game.map_manager.is_walkable(new_pos.x, new_pos.y) then
        player.pos = new_pos
    else
        -- If full movement blocked, try sliding along walls using original (non-normalized) movement
        local slide_x = Vector2.new(player.pos.x + original_movement.x * (player.speed * dt), player.pos.y)
        local slide_y = Vector2.new(player.pos.x, player.pos.y + original_movement.y * (player.speed * dt))

        -- Try horizontal movement
        if original_movement.x ~= 0 and _game.map_manager.is_walkable(slide_x.x, slide_x.y) then
            player.pos = slide_x
            return
        end

        -- Try vertical movement
        if original_movement.y ~= 0 and _game.map_manager.is_walkable(slide_y.x, slide_y.y) then
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

function player.update(dt)
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

    -- Initialize last_tile if not set
    player.last_tile = player.last_tile or Vector2.new(-1, -1)

    -- Check if tile position changed
    if current_tile.x ~= player.last_tile.x or current_tile.y ~= player.last_tile.y then
        -- Update pathfinding data
        player.update_pathfinder(current_tile)
        -- Store new position
        player.last_tile = current_tile
    end

    -- Handle sonic damage
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

function player.draw()
    -- Convert tile position to screen position (snap to integer pixels)
    -- Subtract 1 from position to account for Lua's 1-based indexing
    local screen_x = math.floor((player.pos.x - 1) * _game.map_manager.map.tilewidth)
    local screen_y = math.floor((player.pos.y - 1) * _game.map_manager.map.tileheight)

    -- Get tile dimensions
    local _, _, tile_width, tile_height = player.tile.quad:getViewport()

    if player.tile and player.tile.quad then
        -- Draw sprite centered on player position
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            player.tile.quad,
            screen_x,
            screen_y,
            0,              -- rotation
            1,              -- scale x
            1,              -- scale y
            tile_width / 2, -- origin x (center of sprite)
            tile_height / 2 -- origin y (center of sprite)
        )
    end

    -- Draw active shield on the left side of player
    if player.shield then
        -- Draw shield centered on player position with rotation
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            player.shield.tile.quad,
            screen_x - tile_width,
            screen_y - tile_height / 3
        )
    end

    -- Draw active weapon on top of player
    if player.weapon then
        -- Draw weapon centered on player position with rotation
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            player.weapon.tile.quad,
            screen_x + tile_width / 2,
            screen_y - tile_height * 2 / 3,
            math.rad(45) -- 45 degree rotation
        )
    end
end

function player.draw_ui()
    -- Draw active weapon in UI
    if player.weapon then
        local padding = 8 -- Virtual pixels padding
        local _, _, tile_width, tile_height = player.weapon.tile.quad:getViewport()

        -- Draw at bottom left with padding
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            player.weapon.tile.quad,
            padding,                                    -- x position
            _game.camera.height - padding - tile_height -- y position
        )
    end

    -- Draw active shield in UI
    if player.shield then
        local padding = 8 -- Virtual pixels padding
        local _, _, tile_width, tile_height = player.shield.tile.quad:getViewport()

        -- Draw at bottom left with padding, next to weapon
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            player.shield.tile.quad,
            padding + tile_width + 8,                   -- x position (after weapon)
            _game.camera.height - padding - tile_height -- y position
        )
    end
end

function player.update_pathfinder(current_tile)
    if not current_tile then return end

    -- Get map dimensions from map_manager
    local map_width = _game.map_manager.map.width
    local map_height = _game.map_manager.map.height

    -- Calculate Dijkstra distances from current tile position
    _game.pathfinder.calculate_dijkstra_distances(
        current_tile.x,
        current_tile.y,
        map_width,
        map_height
    )
end

return player
