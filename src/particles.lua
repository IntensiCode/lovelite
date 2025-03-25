local Vector2 = require("src.vector2")

---@class Particle
---@field pos Vector2
---@field velocity Vector2
---@field color table
---@field size number
---@field life number
---@field max_life number
---@field kind string

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
    magic_spread = 0.3  -- Horizontal spread for magic particles
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
        
        -- Create upward velocity with some horizontal spread
        local velocity = Vector2.new(
            (math.random() - 0.5) * particles.magic_spread * particles.magic_speed,  -- Small horizontal movement
            -particles.magic_speed * (0.1 + math.random() * 0.4)  -- Upward movement with some variation
        )
        
        -- Create particle
        table.insert(particles.active, {
            pos = screen_pos + offset,
            velocity = velocity,
            color = {1, 1, 1, 1},  -- Start white
            size = particles.magic_size * (0.8 + math.random() * 0.4),  -- Random size variation
            life = particles.magic_life * (0.8 + math.random() * 0.4),  -- Random life variation
            max_life = particles.magic_life,
            kind = kind  -- Store the specific magic kind
        })
    end
end

function particles.update(dt)
    local i = 1
    while i <= #particles.active do
        local particle = particles.active[i]
        
        -- Update position
        particle.pos = particle.pos + particle.velocity
        
        -- Update life
        particle.life = particle.life - dt
        
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