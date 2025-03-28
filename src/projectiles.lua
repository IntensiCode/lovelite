local lg = love.graphics
local pos = require("src.base.pos")
local particles = require("src.particles")

---@class Projectile
---@field pos pos
---@field direction pos
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

---Get the color for a projectile based on its weapon properties
---@param weapon table The weapon to get the color for
---@return table The color as {r, g, b, a}
local function get_projectile_color(weapon)
    -- Default to white
    local color = { 1, 1, 1, 1 }

    -- Look at the properties to determine the color
    if weapon.lightning then
        color = { 0.8, 0.8, 1, 1 } -- Blue-white
    elseif weapon.fire then
        color = { 1, 0.5, 0, 1 }   -- Orange-red
    elseif weapon.ice then
        color = { 0, 0.5, 1, 1 }   -- Blue
    end

    return color
end

---Draw a melee projectile
---@param proj Projectile The projectile to draw
---@param screen_pos pos The screen position to draw at
local function draw_melee_projectile(proj, screen_pos)
    -- Draw projectile centered and rotated
    local tile_size = DI.dungeon.tile_size
    lg.draw(
        DI.dungeon.map.tilesets[1].image,
        proj.weapon.tile.quad,
        screen_pos.x,
        screen_pos.y,
        proj.rotation,               -- Current rotation
        1, 1,                        -- Scale
        tile_size / 2, tile_size / 2 -- Center origin
    )
end

---Draw a web projectile
---@param screen_pos pos The screen position to draw at
local function draw_web_projectile(screen_pos)
    -- Draw web projectile as a small gray circle
    lg.setColor(0.7, 0.7, 0.7, 1)
    lg.circle("fill", screen_pos.x, screen_pos.y, 2)
    lg.setColor(1, 1, 1, 1)
end

---Draw a magic projectile
---@param proj Projectile The projectile to draw
---@param screen_pos pos The screen position to draw at
local function draw_magic_projectile(proj, screen_pos)
    -- Draw a pulsing circle, with white border, pulsing bigger and smaller
    local pulse_radius = 3 + math.sin(proj.pulse_time * 2) * 2

    -- Get color based on weapon properties
    local color = get_projectile_color(proj.weapon)
    lg.setColor(color[1], color[2], color[3], color[4])
    lg.circle("fill", screen_pos.x, screen_pos.y, pulse_radius)
    lg.setColor(1, 1, 1, 1)
    lg.circle("line", screen_pos.x, screen_pos.y, pulse_radius)
end

---Create a new projectile
---@param data table The projectile data
---@param data.pos pos Starting position
---@param data.direction pos Direction vector
---@param data.weapon table Weapon data
---@param data.owner string Owner type ("player" or "enemy")
function projectiles.spawn(data)
    -- Play appropriate swoosh sound based on weapon type
    if data.weapon.melee then
        DI.sound.play("melee_swoosh", 0.7)
    else
        DI.sound.play("magic_swoosh", 0.8)
    end

    -- Ensure we have pos objects
    local proj_pos = pos.new(data.pos.x, data.pos.y)
    local proj_dir = pos.new(data.direction.x, data.direction.y):normalized()

    if DI.debug.enabled then
        log.debug(string.format("Spawning projectile: pos=(%.2f, %.2f), dir=(%.2f, %.2f), weapon=%s",
            proj_pos.x, proj_pos.y,
            proj_dir.x, proj_dir.y,
            data.weapon.name))
    end

    table.insert(projectiles.active, {
        pos = proj_pos,
        direction = proj_dir,
        weapon = data.weapon,
        owner = data.owner,
        lifetime = data.weapon.lifetime or 0.5,
        speed = data.weapon.speed or 10, -- Add default speed if not specified
        rotation = 0,                    -- Initial rotation
        pulse_time = 0                   -- Initial pulse time for magic projectiles
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
    elseif proj.weapon.melee or proj.weapon.web then
        kind = "dust"
    else
        table.print_deep("proj", proj)
        assert(kind, "No kind found for projectile: " .. proj.weapon.name)
    end
    particles.spawn({
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
    DI.enemies.on_hit(closest_enemy, proj)

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
            proj.pos.x > DI.dungeon.map.width or
            proj.pos.y > DI.dungeon.map.height then
            log.debug("Projectile out of bounds, removing")
            table.remove(projectiles.active, i)
        elseif not DI.collision.is_walkable({
            x = proj.pos.x,
            y = proj.pos.y,
            buffer = pos.new(0.25, 0.1)
        }) then
            -- Play appropriate wall hit sound
            if proj.weapon.melee then
                DI.sound.play("melee_wall_hit", 0.8)
            else
                DI.sound.play("magic_wall_hit", 0.7)
            end
            projectiles.spawn_hit_particles(proj)
            -- Spawn web decal if it's a web projectile
            if proj.weapon.web then
                DI.decals.spawn("web", proj.pos)
            end
            table.remove(projectiles.active, i)
        elseif proj.owner == "player" then
            -- Check for enemy collisions
            local nearby_enemies = DI.enemies.find_enemies_close_to(proj.pos)
            if #nearby_enemies > 0 then
                projectiles.handle_enemy_hit(proj, nearby_enemies)
                table.remove(projectiles.active, i)
            else
                i = i + 1
            end
        elseif proj.owner == "enemy" then
            -- Check if player is hit
            if DI.player.pos:distance(proj.pos) < 0.25 then
                DI.player.on_hit(proj.weapon)
                table.remove(projectiles.active, i)
            else
                i = i + 1
            end
        else
            table.print_deep("proj", proj)
            assert(false, "Unsupported projectile")
        end
    end
end

function projectiles.draw()
    for _, proj in ipairs(projectiles.active) do
        local screen_pos = DI.dungeon.grid_to_screen(proj.pos)
        local tile_size = DI.dungeon.tile_size

        -- Draw a dark gray circle below as pseudo-shadow
        lg.setColor(0.2, 0.2, 0.2, 0.5)
        lg.circle("fill", screen_pos.x, screen_pos.y + tile_size / 3, 3)
        lg.setColor(1, 1, 1, 1)

        if proj.weapon.melee then
            draw_melee_projectile(proj, screen_pos)
        elseif proj.weapon.web then
            draw_web_projectile(screen_pos)
        else
            draw_magic_projectile(proj, screen_pos)
        end
    end
end

return projectiles
