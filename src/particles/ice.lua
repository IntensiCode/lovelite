local Vector2 = require("src.vector2")
local animation = require("src.particles.animation")
local constants = require("src.particles.constants")

local IceParticle = {}
IceParticle.__index = IceParticle

---@param pos Vector2 The position to spawn particles at (in tile space)
---@return table Array of ice particles
function IceParticle.spawn(pos)
    -- Convert tile space position to screen space
    local screen_pos = Vector2.new(
        (pos.x - 1) * _game.map_manager.map.tilewidth,
        (pos.y - 1) * _game.map_manager.map.tileheight
    )
    
    local particles = {}
    for i = 1, constants.magic_count do
        -- Add some randomness to position
        local offset = Vector2.new(
            (math.random() - 0.5) * 4,  -- ±2 pixels
            (math.random() - 0.5) * 4
        )
        
        -- Create velocity with upward movement and spread
        local velocity = Vector2.new(
            (math.random() - 0.5) * constants.magic_spread * constants.magic_speed,
            -constants.magic_speed * (0.1 + math.random() * 0.4)
        )
        
        -- Create particle
        local particle = animation.new(
            screen_pos + offset,
            velocity * 60,
            constants.magic_life * (0.8 + math.random() * 0.4),
            "ice"
        )
        
        table.insert(particles, particle)
    end
    
    return particles
end

return IceParticle 