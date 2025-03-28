local animation = require("src.particles.animation")
local constants = require("src.base.constants")

---Get the color for an ice particle based on its lifetime
---@param t number Normalized lifetime (0 to 1)
---@return table color RGBA color array
local function get_ice_color(t)
    return constants.interpolate_color(t, constants.ice_colors)
end

local IceParticle = {
    spawn = function(pos)
        -- Add some randomness to position
        local offset = pos.new(
            (math.random() - 0.5) * 4, -- ±2 pixels
            (math.random() - 0.5) * 4
        )

        -- Create velocity with upward movement and spread
        local velocity = pos.new(
            (math.random() - 0.5) * constants.magic_spread * constants.magic_speed,
            -constants.magic_speed * (0.1 + math.random() * 0.4)
        )

        -- Create particle with color hook and animation data
        return animation.new(
            pos + offset,
            velocity * 60,
            constants.magic_life * (0.8 + math.random() * 0.4),
            "ice",
            get_ice_color,
            constants.ice_animation
        )
    end
}

return IceParticle
