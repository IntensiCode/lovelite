local Vector2 = require("src.vector2")
local animation = require("src.particles.animation")
local LightningParticle = require("src.particles.lightning")
local DustParticle = require("src.particles.dust")
local FireParticle = require("src.particles.fire")
local IceParticle = require("src.particles.ice")
local events = require("src.events")
local constants = require("src.particles.constants")

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
    active = {},                -- Array of active particles
    -- Magic settings
    magic_count = 6,            -- Number of particles per magic effect
    magic_speed = 1,            -- Base upward speed for magic particles
    magic_size = 3,             -- Size of magic particles in pixels
    magic_life = 0.8,           -- Life in seconds for magic particles
    magic_spread = 0.3,         -- Horizontal spread for magic particles
    -- Lightning specific settings
    lightning_delay_max = 0.1,  -- Maximum random delay for lightning strikes
    lightning_drift_speed = 0.1 -- How fast lightning particles drift horizontally
}

---@param pos Vector2 The position to spawn particles at (in tile space)
---@param kind string The kind of particle effect ("fire", "ice", "lightning", "dust")
---@param direction? Vector2 Optional direction for dust particles
function particles.spawn(pos, kind, direction)
    local spawned_particles = {}

    if kind == "fire" then
        spawned_particles = FireParticle.spawn(pos)
    elseif kind == "ice" then
        spawned_particles = IceParticle.spawn(pos)
    elseif kind == "lightning" then
        spawned_particles = LightningParticle.spawn(pos)
    elseif kind == "dust" then
        assert(direction, "Direction is required for dust particles")
        spawned_particles = DustParticle.spawn(pos, direction)
    end

    -- Add all spawned particles to active particles
    for _, particle in ipairs(spawned_particles) do
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
        if particle:update(dt) then
            table.remove(particles.active, i)
            goto continue
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
        particle:draw()
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Add particles to global game variable when loaded
_game = _game or {}
_game.particles = particles

-- Register for particle spawn events
events.register("particles.spawn", function(data)
    particles.spawn(data.pos, data.kind, data.direction)
end)

return particles
