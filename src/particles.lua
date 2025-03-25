local Vector2 = require("src.vector2")

---@class Particle
---@field pos Vector2
---@field velocity Vector2
---@field color table
---@field size number
---@field life number
---@field max_life number

local particles = {
    active = {},  -- Array of active particles
    dust_count = 4,  -- Number of particles per dust effect
    dust_speed = 2,  -- Base speed for dust particles
    dust_size = 2,   -- Size of dust particles in pixels
    dust_life = 0.5  -- Life in seconds for dust particles
}

---@param pos Vector2 The position to spawn particles at (in tile space)
---@param direction Vector2 The direction the particles should move in
function particles.spawn_dust(pos, direction)
    -- Convert tile space position to screen space
    local screen_pos = Vector2.new(
        (pos.x - 1) * _game.map_manager.map.tilewidth,
        (pos.y - 1) * _game.map_manager.map.tileheight
    )
    
    -- Create multiple particles in a small area
    for i = 1, particles.dust_count do
        -- Add some randomness to position
        local offset = Vector2.new(
            (math.random() - 0.5) * 4,  -- ±2 pixels
            (math.random() - 0.5) * 4
        )
        
        -- Add some randomness to velocity
        local angle = math.atan2(direction.y, direction.x)
        local spread = math.pi / 4  -- 45 degree spread
        local particle_angle = angle + (math.random() - 0.5) * spread
        local speed = particles.dust_speed * (0.5 + math.random() * 0.5)  -- 50-100% of base speed
        local velocity = Vector2.new(
            math.cos(particle_angle) * speed,
            math.sin(particle_angle) * speed
        )
        
        -- Create particle
        table.insert(particles.active, {
            pos = screen_pos + offset,
            velocity = velocity,
            color = {1, 1, 1, 1},  -- Start white
            size = particles.dust_size,
            life = particles.dust_life,
            max_life = particles.dust_life
        })
    end
end

function particles.update(dt)
    local i = 1
    while i <= #particles.active do
        local particle = particles.active[i]

        -- print("Updating particle", i, "at", particle.pos, "with velocity", particle.velocity)
        
        -- Update position
        particle.pos = particle.pos + particle.velocity
        
        -- Update life
        particle.life = particle.life - dt
        
        -- Update color (fade from white to gray while becoming transparent)
        local t = particle.life / particle.max_life
        local gray = 0.5 + 0.5 * t  -- Fade from 1 to 0.5
        particle.color = {gray, gray, gray, t}
        
        -- Remove dead particles
        if particle.life <= 0 then
            table.remove(particles.active, i)
        else
            i = i + 1
        end
    end
end

function particles.draw()
    for _, particle in ipairs(particles.active) do
        love.graphics.setColor(unpack(particle.color))
        love.graphics.circle("fill", particle.pos.x, particle.pos.y, particle.size)
    end
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

-- Add particles to global game variable when loaded
_game = _game or {}
_game.particles = particles

return particles 