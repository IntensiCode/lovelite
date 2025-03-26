local Vector2 = require("src.vector2")
local animation = require("src.particles.animation")
local LightningParticle = require("src.particles.lightning")
local DustParticle = require("src.particles.dust")
local events = require("src.events")

---@class Particle
---@field pos Vector2
---@field velocity Vector2
---@field color table
---@field size number
---@field life number
---@field max_life number
---@field kind string
---@field jitter1 Vector2 Random offset for first zag point
---@field jitter2 Vector2 Random offset for middle point
---@field jitter3 Vector2 Random offset for second zag point
---@field jitter_time number Time counter for jitter movement
---@field delay number Delay before particle becomes visible (for lightning)
---@field flip_x boolean Whether to flip the x-axis for lightning strikes

local particles = {
    active = {},  -- Array of active particles
    -- Magic settings
    magic_count = 6,  -- Number of particles per magic effect
    magic_speed = 1,  -- Base upward speed for magic particles
    magic_size = 3,   -- Size of magic particles in pixels
    magic_life = 0.8,  -- Life in seconds for magic particles
    magic_spread = 0.3,  -- Horizontal spread for magic particles
    -- Lightning specific settings
    lightning_delay_max = 0.1,  -- Maximum random delay for lightning strikes
    lightning_drift_speed = 0.1  -- How fast lightning particles drift horizontally
}

---@param pos Vector2 The position to spawn particles at (in tile space)
---@param direction Vector2 The direction the particles should move in
function particles.spawn_dust(pos, direction)
    -- Create dust particles and add them to active particles
    local dust_particles = DustParticle.spawn(pos, direction)
    for _, particle in ipairs(dust_particles) do
        table.insert(particles.active, particle)
    end
end

---@param pos Vector2 The position to spawn particles at (in tile space)
---@param kind string The kind of magic effect ("fire", "ice", "lightning", etc.)
function particles.spawn_magic(pos, kind)
    -- Convert tile space position to screen space
    local screen_pos = Vector2.new(
        (pos.x - 1) * _game.map_manager.map.tilewidth,
        (pos.y - 1) * _game.map_manager.map.tileheight
    )
    
    -- Create multiple particles in a small area
    for i = 1, particles.magic_count do
        -- Add some randomness to position
        local offset = Vector2.new(
            (math.random() - 0.5) * 4,  -- ±2 pixels
            (math.random() - 0.5) * 4
        )
        
        -- Create velocity based on particle type
        local velocity
        if kind == "lightning" then
            -- Lightning moves horizontally with slight random direction
            local direction = math.random() < 0.5 and -1 or 1  -- Random left or right
            velocity = Vector2.new(
                direction * particles.lightning_drift_speed * (0.8 + math.random() * 0.4),
                0  -- No vertical movement
            )
        else
            -- Other particles move upward with spread
            velocity = Vector2.new(
                (math.random() - 0.5) * particles.magic_spread * particles.magic_speed,
                -particles.magic_speed * (0.1 + math.random() * 0.4)
            )
        end
        
        -- Create particle
        local particle
        if kind == "fire" or kind == "ice" then
            particle = animation.new(
                screen_pos + offset,
                velocity * 60,
                particles.magic_life * (0.8 + math.random() * 0.4),
                kind
            )
        elseif kind == "lightning" then
            particle = LightningParticle.new(
                screen_pos + offset,
                velocity * 60,
                particles.magic_life * (0.8 + math.random() * 0.4),
                particles.magic_size * (0.8 + math.random() * 0.4),
                math.random() * particles.lightning_delay_max
            )
        end
        
        table.insert(particles.active, particle)
    end
end

function particles.update(dt)
    local i = 1
    while i <= #particles.active do
        local particle = particles.active[i]
        
        -- Update delay
        if particle.delay and particle.delay > 0 then
            particle.delay = particle.delay - dt
        end
        
        -- Update particle
        if particle.update then
            -- Use particle's own update method (for AnimatedParticle, LightningParticle, or DustParticle)
            if particle:update(dt) then
                table.remove(particles.active, i)
                goto continue
            end
        else
            -- Basic particle update
            particle.pos = particle.pos + particle.velocity -- * dt
            particle.life = particle.life - dt
            if particle.life <= 0 then
                table.remove(particles.active, i)
                goto continue
            end
        end
        
        -- Update color based on particle kind
        local t = particle.life / particle.max_life
        if particle.kind == "ice" then
            particle.color = animation.get_ice_color(t)
        elseif particle.kind == "fire" then
            particle.color = animation.get_fire_color(t)
        elseif particle.kind == "lightning" then
            particle.color = LightningParticle.get_color(t)
        end
        
        i = i + 1
        ::continue::
    end
end

function particles.draw()
    for _, particle in ipairs(particles.active) do
        if particle.delay and particle.delay > 0 then
            return
        end

        love.graphics.setColor(unpack(particle.color))
        if particle.draw then
            -- Use particle's own draw method (for AnimatedParticle, LightningParticle, or DustParticle)
            particle:draw()
        else
            local size = particle.size or 3
            love.graphics.circle("fill", particle.pos.x, particle.pos.y, size)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Add particles to global game variable when loaded
_game = _game or {}
_game.particles = particles

-- Register for particle spawn events
events.register("particles.spawn.magic", function(data)
    particles.spawn_magic(data.pos, data.kind)
end)

events.register("particles.spawn.dust", function(data)
    particles.spawn_dust(data.pos, data.direction)
end)

return particles 