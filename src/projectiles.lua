local Vector2 = require("src.vector2")

---@class Projectile
---@field pos Vector2
---@field direction Vector2
---@field speed number
---@field rotation number
---@field weapon table

local projectiles = {
    active = {},  -- Array of active projectiles
    rotation_speed = math.pi  -- Radians per second (half rotation)
}

---@param pos Vector2 The starting position of the projectile
---@param direction Vector2 The direction the projectile will travel
---@param weapon table The weapon that fired the projectile
function projectiles.spawn(pos, direction, weapon)
    table.insert(projectiles.active, {
        pos = Vector2.new(pos.x, pos.y),
        direction = direction:normalized(),  -- Ensure normalized
        speed = weapon.speed,
        rotation = 0,
        weapon = weapon  -- Store entire weapon for future use
    })
end

function projectiles.update(dt)
    local i = 1
    while i <= #projectiles.active do
        local proj = projectiles.active[i]
        
        -- Update position
        proj.pos = proj.pos + proj.direction * (proj.speed * dt)
        
        -- Update rotation
        proj.rotation = proj.rotation + projectiles.rotation_speed * dt
        
        -- Check if outside map bounds
        if proj.pos.x < 1 or proj.pos.y < 1 or 
           proj.pos.x > _game.map_manager.map.width or 
           proj.pos.y > _game.map_manager.map.height then
            table.remove(projectiles.active, i)
        else
            -- Check if projectile hit a non-walkable tile with a smaller buffer
            if not _game.map_manager.is_walkable(proj.pos.x, proj.pos.y, Vector2.new(0.25, 0.1)) then
                -- Spawn dust particles at the point of impact
                _game.particles.spawn_dust(proj.pos, proj.direction)
                table.remove(projectiles.active, i)
            else
                i = i + 1
            end
        end
    end
end

function projectiles.draw()
    for _, proj in ipairs(projectiles.active) do
        local screen_x = math.floor((proj.pos.x - 1) * _game.map_manager.map.tilewidth)
        local screen_y = math.floor((proj.pos.y - 1) * _game.map_manager.map.tileheight)
        
        -- Get tile dimensions
        local _, _, tile_width, tile_height = proj.weapon.tile.quad:getViewport()

        -- Draw a dark gray circle below as pseudo-shadow
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.circle("fill", screen_x , screen_y + tile_height/3, 3)
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Draw projectile centered and rotated
        love.graphics.draw(
            _game.map_manager.map.tilesets[1].image,
            proj.weapon.tile.quad,
            screen_x,
            screen_y,
            proj.rotation,  -- Current rotation
            1, 1,  -- Scale
            tile_width/2, tile_height/2  -- Center origin
        )
    end
end

return projectiles 