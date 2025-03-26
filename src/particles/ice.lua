local Vector2 = require("src.vector2")
local animation = require("src.particles.animation")
local constants = require("src.particles.constants")

-- Ice particle animation data
local ice_animation = {
    frames = {
        {     -- Frame 1: Basic crystal
            { 0, 0, 1, 0, 0 },
            { 0, 1, 1, 1, 0 },
            { 1, 1, 0, 1, 1 },
            { 0, 1, 1, 1, 0 },
            { 0, 0, 1, 0, 0 }
        },
        {     -- Frame 2: Sparkle top-right
            { 0, 0, 1, 1, 0 },
            { 0, 1, 1, 1, 0 },
            { 1, 1, 0, 1, 1 },
            { 0, 1, 1, 1, 0 },
            { 0, 0, 1, 0, 0 }
        },
        {     -- Frame 3: Sparkle bottom-left
            { 0, 0, 1, 0, 0 },
            { 0, 1, 1, 1, 0 },
            { 1, 1, 0, 1, 1 },
            { 1, 1, 1, 1, 0 },
            { 0, 0, 1, 0, 0 }
        },
        {     -- Frame 4: Crystal slightly rotated
            { 0, 1, 1, 0, 0 },
            { 0, 1, 1, 1, 0 },
            { 1, 1, 0, 1, 1 },
            { 0, 1, 1, 1, 0 },
            { 0, 0, 1, 1, 0 }
        }
    },
    frame_duration = 0.15,     -- Slightly slower than fire
    pixel_size = 2
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

local IceParticle = {
    spawn = function(pos)
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
            
            -- Create particle with color hook and animation data
            local particle = animation.new(
                screen_pos + offset,
                velocity * 60,
                constants.magic_life * (0.8 + math.random() * 0.4),
                "ice",
                get_ice_color,
                ice_animation
            )
            
            table.insert(particles, particle)
        end
        
        return particles
    end
}

return IceParticle 