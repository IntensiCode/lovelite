local Vector2 = require("src.vector2")
local animation = require("src.particles.animation")
local constants = require("src.particles.constants")

-- Fire particle animation data
local fire_animation = {
    frames = {
        {
            { 0, 0, 1, 0, 0 },
            { 0, 1, 1, 1, 0 },
            { 1, 1, 1, 1, 1 },
            { 0, 1, 1, 1, 0 },
            { 0, 0, 1, 0, 0 }
        },
        {
            { 0, 1, 0, 1, 0 },
            { 1, 1, 1, 1, 1 },
            { 0, 1, 1, 1, 0 },
            { 0, 1, 1, 1, 0 },
            { 0, 0, 1, 0, 0 }
        },
        {
            { 0, 0, 1, 0, 0 },
            { 0, 1, 1, 1, 0 },
            { 1, 1, 1, 1, 1 },
            { 0, 1, 1, 1, 0 },
            { 0, 1, 0, 1, 0 }
        },
        {
            { 0, 1, 0, 1, 0 },
            { 1, 1, 1, 1, 1 },
            { 0, 1, 1, 1, 0 },
            { 0, 1, 0, 1, 0 },
            { 0, 0, 1, 0, 0 }
        }
    },
    frame_duration = 0.1,
    pixel_size = 2     -- Size of each pixel in the animation
}

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

local FireParticle = {
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
                "fire",
                get_fire_color,
                fire_animation
            )
            
            table.insert(particles, particle)
        end
        
        return particles
    end
}

return FireParticle 