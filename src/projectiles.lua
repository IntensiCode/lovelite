local Vector2 = require("src.base.vector2")
local events = require("src.base.events")

---@class Projectile
---@field pos Vector2
---@field direction Vector2
---@field speed number
---@field rotation number
---@field weapon table
---@field owner string
---@field lifetime number
---@field pulse_time number

local projectiles = {
    active = {},             -- Array of active projectiles
    rotation_speed = math.pi -- Radians per second (half rotation)
}

---Create a new projectile
---@param pos Vector2 Starting position
---@param direction Vector2 Direction vector
---@param weapon table Weapon data
---@param owner string Owner type ("player" or "enemy")
function projectiles.spawn(pos, direction, weapon, owner)
    -- Play appropriate swoosh sound based on weapon type
    if weapon.melee then
        _game.sound.play("melee_swoosh", 0.7)
    else
        _game.sound.play("magic_swoosh", 0.8)
    end

    -- Ensure we have Vector2 objects
    local proj_pos = Vector2.new(pos.x, pos.y)
    local proj_dir = Vector2.new(direction.x, direction.y):normalized()

    table.insert(projectiles.active, {
        pos = proj_pos,
        direction = proj_dir,
        weapon = weapon,
        owner = owner,
        lifetime = weapon.lifetime or 0.5,
        speed = weapon.speed or 10,  -- Add default speed if not specified
        rotation = 0,                -- Initial rotation
        pulse_time = 0              -- Initial pulse time for magic projectiles
    })
end

---@param proj Projectile The projectile that hit something
function projectiles.spawn_hit_particles(proj)
    -- Determine particle kind from weapon properties
    local kind = nil
    if proj.weapon.lightning then
        kind = "lightning"
    elseif proj.weapon.ice then
        kind = "ice"
    elseif proj.weapon.fire then
        kind = "fire"
    elseif proj.weapon.melee then
        kind = "dust"
    end
    assert(kind, "No kind found for projectile")
    events.send("particles.spawn", {
        pos = proj.pos,
        kind = kind,
        direction = proj.direction
    })
end

---@param proj Projectile The projectile that hit the enemy
---@param nearby_enemies Enemy[] Array of nearby enemies
function projectiles.handle_enemy_hit(proj, nearby_enemies)
    -- Find the closest enemy
    local closest_enemy = nearby_enemies[1]
    local min_distance = (closest_enemy.pos - proj.pos):length()

    for j = 2, #nearby_enemies do
        local distance = (nearby_enemies[j].pos - proj.pos):length()
        if distance < min_distance then
            closest_enemy = nearby_enemies[j]
            min_distance = distance
        end
    end

    -- Hit the closest enemy
    _game.enemies.on_hit(closest_enemy, proj)

    -- Spawn hit particles
    projectiles.spawn_hit_particles(proj)
end

function projectiles.update(dt)
    local i = 1
    while i <= #projectiles.active do
        local proj = projectiles.active[i]

        -- Update position
        proj.pos = proj.pos + proj.direction * (proj.speed * dt)

        -- Update rotation
        proj.rotation = proj.rotation + projectiles.rotation_speed * dt

        -- Use proj.pulse_time to pulse the circle (magic projectiles only)
        proj.pulse_time = (proj.pulse_time or 0) + dt

        -- Check if outside map bounds
        if proj.pos.x < 1 or proj.pos.y < 1 or
            proj.pos.x > _game.map_manager.map.width or
            proj.pos.y > _game.map_manager.map.height then
            table.remove(projectiles.active, i)
        else
            -- Check for enemy collisions
            local nearby_enemies = _game.enemies.find_enemies_close_to(proj.pos)
            if #nearby_enemies > 0 then
                projectiles.handle_enemy_hit(proj, nearby_enemies)
                table.remove(projectiles.active, i)
            elseif not _game.map_manager.is_walkable(proj.pos.x, proj.pos.y, Vector2.new(0.25, 0.1)) then
                -- Play appropriate wall hit sound
                if proj.weapon.melee then
                    _game.sound.play("melee_wall_hit", 0.8)
                else
                    _game.sound.play("magic_wall_hit", 0.7)
                end
                projectiles.spawn_hit_particles(proj)
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
        love.graphics.circle("fill", screen_x, screen_y + tile_height / 3, 3)
        love.graphics.setColor(1, 1, 1, 1)

        if proj.weapon.melee then
            -- Draw projectile centered and rotated
            love.graphics.draw(
                _game.map_manager.map.tilesets[1].image,
                proj.weapon.tile.quad,
                screen_x,
                screen_y,
                proj.rotation,                  -- Current rotation
                1, 1,                           -- Scale
                tile_width / 2, tile_height / 2 -- Center origin
            )
        else
            -- Draw a pulsing circle, with white border, pulsing bigger and smaller
            local pulse_radius = 3 + math.sin(proj.pulse_time * 2) * 2
            -- Look at the properties to determine the color
            -- - if lightning is set, use bluewhite
            -- - if fire is set, use red
            -- - if ice is set, use blue
            -- - if poison is set, use green
            -- - if electric is set, use yellow
            -- - if dark is set, use black
            -- - if light is set, use white
            local color = { 1, 1, 1, 1 }
            if proj.weapon.lightning then
                color = { 0.8, 0.8, 1, 1 }
            elseif proj.weapon.fire then
                color = { 1, 0.5, 0, 1 }
            elseif proj.weapon.ice then
                color = { 0, 0.5, 1, 1 }
            end
            love.graphics.setColor(color[1], color[2], color[3], color[4])
            love.graphics.circle("fill", screen_x, screen_y, pulse_radius)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.circle("line", screen_x, screen_y, pulse_radius)
        end
    end
end

-- Register for projectile spawn events (moved to end of file)
events.register("projectile.spawn", function(data)
    projectiles.spawn(data.pos, data.direction, data.weapon, "player")
end)

return projectiles
