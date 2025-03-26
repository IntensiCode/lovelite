local Vector2 = require("src.vector2")
local animation = require("src.particles.animation")

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
    -- Dust settings
    dust_count = 4,  -- Number of particles per dust effect
    dust_speed = 2,  -- Base speed for dust particles
    dust_size = 2,   -- Size of dust particles in pixels
    dust_life = 0.5,  -- Life in seconds for dust particles
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

---Get the color for an ice particle based on its lifetime
---@param t number Normalized lifetime (0 to 1)
---@return table color RGBA color array
local function get_ice_color(t)
    if t > 0.6 then
        -- Dark blue to blue (0,0,0.8) -> (0,0.3,1)
        local blend = (t - 0.6) / 0.4
        return {
            0,                   -- stays 0
            0.3 * blend,        -- 0 -> 0.3
            0.8 + 0.2 * blend,  -- 0.8 -> 1
            1
        }
    elseif t > 0.2 then
        -- Blue to turkish blue (0,0.3,1) -> (0,0.6,1)
        local blend = (t - 0.2) / 0.4
        return {
            0,                   -- stays 0
            0.3 + 0.3 * blend,  -- 0.3 -> 0.6
            1,                   -- stays 1
            1
        }
    else
        -- Fade out turkish blue
        return {0, 0.6, 1, t * 5}
    end
end

---Get the color for a lightning particle based on its lifetime
---@param t number Normalized lifetime (0 to 1)
---@return table color RGBA color array
local function get_lightning_color(t)
    if t > 0.75 then
        -- White (1,1,1)
        return {1, 1, 1, 1}
    elseif t > 0.5 then
        -- Yellow (1,1,0)
        return {1, 1, 0, 1}
    elseif t > 0.25 then
        -- White again (1,1,1)
        return {1, 1, 1, 1}
    else
        -- Black to transparent (0,0,0) -> (0,0,0,0)
        return {0, 0, 0, t * 4}
    end
end

---Get the color for a fire particle based on its lifetime
---@param t number Normalized lifetime (0 to 1)
---@return table color RGBA color array
local function get_fire_color(t)
    if t > 0.6 then
        -- White to yellow (1,1,1) -> (1,1,0)
        local yellow = (t - 0.6) / 0.4  -- 0 to 1
        return {1, 1, yellow, 1}
    elseif t > 0.2 then
        -- Yellow to red (1,1,0) -> (1,0,0)
        local red = (t - 0.2) / 0.4  -- 0 to 1
        return {1, red, 0, 1}
    else
        -- Red to transparent (1,0,0) -> (1,0,0,0)
        return {1, 0, 0, t * 5}  -- Fade out in last 20%
    end
end

---Draw a stylized lightning strike
---@param x number Center x position
---@param y number Center y position
---@param size number Base size of the lightning
---@param jitter1 Vector2 Offset for first zag point
---@param jitter2 Vector2 Offset for middle point
---@param jitter3 Vector2 Offset for second zag point
---@param scale_y number Vertical scale factor (0 to 1)
---@param flip_x boolean Whether to flip the x-axis pattern
local function draw_lightning_strike(x, y, size, jitter1, jitter2, jitter3, scale_y, flip_x)
    -- Draw a vertical zigzag pattern with jittered points
    -- Scale the zigzag width progressively larger towards the bottom
    -- Apply vertical scaling to make it grow
    love.graphics.setLineWidth(1)
    local x_mult = flip_x and -1 or 1  -- Multiplier for x coordinates
    love.graphics.line(
        x, y,     -- Start point (at center)
        x + x_mult * (-size/6) + jitter1.x, y + (-size/4 + jitter1.y) * scale_y,  -- First zag (small)
        x + jitter2.x, y + jitter2.y * scale_y,         -- Middle point
        x + x_mult * (size/3) + jitter3.x, y + (size/2 + jitter3.y) * scale_y,   -- Second zag (larger)
        x, y + size * scale_y       -- End point (scaled by growth)
    )
end

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
            max_life = particles.dust_life,
            kind = "dust"
        })
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
        else
            -- Create lightning or basic particle
            particle = {
                pos = screen_pos + offset,
                velocity = velocity,
                color = {1, 1, 1, 1},
                size = particles.magic_size * (0.8 + math.random() * 0.4),
                life = particles.magic_life * (0.8 + math.random() * 0.4),
                max_life = particles.magic_life,
                kind = kind,
                jitter_time = math.random() * math.pi * 2,
                jitter1 = Vector2.new(0, 0),
                jitter2 = Vector2.new(0, 0),
                jitter3 = Vector2.new(0, 0),
                delay = kind == "lightning" and math.random() * particles.lightning_delay_max or 0,
                flip_x = math.random() < 0.5
            }
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
            -- Use particle's own update method (for AnimatedParticle)
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
        
        -- Update jitter for lightning particles
        if particle.kind == "lightning" and particle.delay <= 0 then
            particle.jitter_time = particle.jitter_time + dt * 10  -- Speed of jitter movement
            local jitter_amount = particle.size * 0.5  -- Scale jitter with particle size
            
            -- Update each jitter point with smooth random movement
            particle.jitter1 = Vector2.new(
                math.sin(particle.jitter_time * 0.7) * jitter_amount,
                math.cos(particle.jitter_time * 0.3) * jitter_amount
            )
            particle.jitter2 = Vector2.new(
                math.sin(particle.jitter_time * 0.1) * jitter_amount,
                math.cos(particle.jitter_time * 0.9) * jitter_amount
            )
            particle.jitter3 = Vector2.new(
                math.sin(particle.jitter_time * 0.5) * jitter_amount,
                math.cos(particle.jitter_time * 0.5) * jitter_amount
            )
        end
        
        -- Update color based on particle kind
        local t = particle.life / particle.max_life
        if particle.kind == "dust" then
            -- Dust: fade from white to gray while becoming transparent
            local gray = 0.5 + 0.5 * t  -- Fade from 1 to 0.5
            particle.color = {gray, gray, gray, t}
        else  -- magic effects
            if particle.kind == "ice" then
                particle.color = get_ice_color(t)
            elseif particle.kind == "lightning" then
                particle.color = get_lightning_color(t)
            else  -- "fire" (default)
                particle.color = get_fire_color(t)
            end
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
        if particle.kind == "lightning" then
            -- Calculate growth based on lifetime
            local growth = math.min(1, (1 - particle.life / particle.max_life) * 4)
            draw_lightning_strike(
                particle.pos.x, 
                particle.pos.y, 
                particle.size * 3,
                particle.jitter1,
                particle.jitter2,
                particle.jitter3,
                growth,
                particle.flip_x
            )
        elseif particle.draw then
            -- Use particle's own draw method (for AnimatedParticle)
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

return particles 