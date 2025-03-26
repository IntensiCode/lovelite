local Vector2 = require("src.vector2")
local animation = require("src.particles.animation")

local FireParticle = {}
FireParticle.__index = FireParticle

---@param pos Vector2 The position to spawn particles at (in tile space)
---@param count number Number of particles to spawn
---@param speed number Base speed of particles
---@param spread number Horizontal spread factor
---@param life number Base lifetime of particles
---@return table Array of fire particles
function FireParticle.spawn(pos, count, speed, spread, life)
    -- Convert tile space position to screen space
    local screen_pos = Vector2.new(
        (pos.x - 1) * _game.map_manager.map.tilewidth,
        (pos.y - 1) * _game.map_manager.map.tileheight
    )
    
    local particles = {}
    for i = 1, count do
        -- Add some randomness to position
        local offset = Vector2.new(
            (math.random() - 0.5) * 4,  -- ±2 pixels
            (math.random() - 0.5) * 4
        )
        
        -- Create velocity with upward movement and spread
        local velocity = Vector2.new(
            (math.random() - 0.5) * spread * speed,
            -speed * (0.1 + math.random() * 0.4)
        )
        
        -- Create particle
        local particle = animation.new(
            screen_pos + offset,
            velocity * 60,
            life * (0.8 + math.random() * 0.4),
            "fire"
        )
        
        table.insert(particles, particle)
    end
    
    return particles
end

return FireParticle 