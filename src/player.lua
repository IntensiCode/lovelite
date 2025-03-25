local Vector2 = require("src.vector2")

---@class Player
---@field pos Vector2
---@field tile_id number
---@field tile table
---@field speed number
---@field weapon table
---@field tile_size number
---@field last_direction Vector2
---@field cooldown number
local player = {
    pos = Vector2.new(0, 0),
    tile_id = nil,
    tile = nil,
    speed = 5,  -- tiles per second
    weapon = nil,
    tile_size = nil,
    last_direction = Vector2.new(1, 0),  -- Default facing right
    cooldown = 0  -- Initialize cooldown to 0
}

function player.load()
    local setup = _game.map_manager.get_player_start_position()
    print("Player setup:", setup)
    print("Player position:", setup.pos)
    print("Player tile:", setup.tile)
    
    player.pos = setup.pos
    player.tile = setup.tile
    player.tile_id = setup.tile.id
    
    -- Get tile size from tileset
    player.tile_size = _game.map_manager.map.tilewidth
    
    -- Assign initial weapon
    player.weapon = nil
    for gid, weapon in pairs(_game.map_manager.weapons) do
        if weapon.initial then
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

    -- Set cooldown and spawn projectile
    player.cooldown = player.weapon.cooldown
    _game.projectiles.spawn(
        player.pos,
        player.last_direction,
        player.weapon
    )
end

---@param dt number Delta time in seconds
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
    player.cooldown = math.max(0, player.cooldown - dt)
    
    -- Handle shooting
    player.handle_shooting()
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
            0,  -- rotation
            1,  -- scale x
            1,  -- scale y
            tile_width/2,  -- origin x (center of sprite)
            tile_height/2  -- origin y (center of sprite)
        )
    end

    -- Draw active weapon on top of player
    if player.weapon then
        -- Draw weapon centered on player position with rotation
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            player.weapon.tile.quad,
            screen_x + tile_width/2,
            screen_y - tile_height*2/3,
            math.rad(45)  -- 45 degree rotation
        )
    end
end

function player.draw_ui()
    -- Draw active weapon in UI
    if player.weapon then
        local padding = 8  -- Virtual pixels padding
        local _, _, tile_width, tile_height = player.weapon.tile.quad:getViewport()
        
        -- Draw at bottom left with padding
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            player.weapon.tile.quad,
            padding,  -- x position
            _game.camera.height - padding - tile_height  -- y position
        )
    end
end

return player 