local LightningParticle = require("src.particles.lightning")
local Vector2 = require("src.base.vector2")
local DustParticle = require("src.particles.dust")
local FireParticle = require("src.particles.fire")
local IceParticle = require("src.particles.ice")
local events = require("src.base.events")
local constants = require("src.base.constants")

---@class Particle
---@field pos Vector2 The position of the particle
---@field color table The color of the particle
---@field life number The remaining lifetime of the particle
---@field max_life number The maximum lifetime of the particle
---@field kind string The kind of particle effect ("fire", "ice", "lightning", "dust")
---@field delay number Delay before particle becomes visible (for lightning)

local particles = {
    active = {} -- Array of active particles
}

---@param data table The particle spawn data
---@param data.pos Vector2 The position to spawn particles at (in tile space)
---@param data.kind string The kind of particle effect ("fire", "ice", "lightning", "dust")
---@param data.direction? Vector2 Optional direction for dust particles
---@param data.count? number Optional count of particles to spawn (defaults to magic_count or dust_particle_count)
function particles.spawn(data)
    -- Convert tile space position to screen space
    local screen_pos = Vector2.new(
        (data.pos.x - 1) * _game.dungeon.map.tilewidth,
        (data.pos.y - 1) * _game.dungeon.map.tileheight
    )

    -- Use provided count or default based on particle type
    local count = data.count or (data.kind == "dust" and constants.dust_particle_count or constants.magic_count)
    for i = 1, count do
        local particle
        if data.kind == "fire" then
            particle = FireParticle.spawn(screen_pos)
        elseif data.kind == "ice" then
            particle = IceParticle.spawn(screen_pos)
        elseif data.kind == "lightning" then
            particle = LightningParticle.spawn(screen_pos)
        elseif data.kind == "dust" then
            particle = DustParticle.spawn(screen_pos, data.direction)
        end
        assert(particle, "Failed to spawn particle")
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
        particle:update(dt)

        -- Check if particle should be removed
        if particle.life <= 0 then
            table.remove(particles.active, i)
            goto continue
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
    particles.spawn(data)
end)

return particles
