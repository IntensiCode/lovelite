-- Magic particle settings
local constants = {
    -- Magic settings
    magic_count = 6,    -- Number of particles per magic effect
    magic_speed = 1,    -- Base upward speed for magic particles
    magic_size = 3,     -- Size of magic particles in pixels
    magic_life = 0.8,   -- Life in seconds for magic particles
    magic_spread = 0.3, -- Horizontal spread for magic particles

    -- Lightning specific settings
    lightning_delay_max = 0.1,   -- Maximum random delay for lightning strikes
    lightning_drift_speed = 0.1, -- How fast lightning particles drift horizontally

    -- Color interpolation function
    ---@param t number Normalized time (0 to 1)
    ---@param color_stops table Array of {time, color} pairs, where time is 0-1 and color is {r,g,b,a}
    ---@return table color Interpolated color
    interpolate_color = function(t, color_stops)
        -- Handle edge cases
        if t >= 1 then
            return color_stops[1][2]            -- Use first color when t = 1
        elseif t <= 0 then
            return color_stops[#color_stops][2] -- Use last color when t = 0
        end

        -- Find the two color stops to interpolate between
        local start_stop, end_stop
        for i = 1, #color_stops - 1 do
            if t >= color_stops[i][1] and t <= color_stops[i + 1][1] then
                start_stop = color_stops[i]
                end_stop = color_stops[i + 1]
                break
            end
        end

        -- If we're between stops, interpolate
        if start_stop and end_stop then
            -- Calculate interpolation factor
            local t_start, t_end = start_stop[1], end_stop[1]
            local factor = (t - t_start) / (t_end - t_start)

            -- Interpolate each color component
            local start_color, end_color = start_stop[2], end_stop[2]
            return {
                start_color[1] + (end_color[1] - start_color[1]) * factor,
                start_color[2] + (end_color[2] - start_color[2]) * factor,
                start_color[3] + (end_color[3] - start_color[3]) * factor,
                start_color[4] + (end_color[4] - start_color[4]) * factor
            }
        end

        -- If we're not between stops, find the closest stop
        local closest_stop = color_stops[1]
        local min_diff = math.abs(t - color_stops[1][1])

        for i = 2, #color_stops do
            local diff = math.abs(t - color_stops[i][1])
            if diff < min_diff then
                min_diff = diff
                closest_stop = color_stops[i]
            end
        end

        return closest_stop[2]
    end,

    -- Pathfinder rainbow colors (red, orange, yellow, green, blue, purple but reversed)
    pathfinder_colors = {
        { 0.0, { 0.5, 0, 1, 1 } }, -- Purple
        { 0.2, { 0, 0, 1, 1 } },   -- Blue
        { 0.4, { 0, 1, 0, 1 } },   -- Green
        { 0.6, { 1, 1, 0, 1 } },   -- Yellow
        { 0.8, { 1, 0.5, 0, 1 } }, -- Orange
        { 1.0, { 1, 0, 0, 1 } },   -- Red
    },

    -- Fire particle color stops (ordered from t=1 to t=0)
    fire_colors = {
        { 1.0, { 1, 1, 1, 1 } }, -- White
        { 0.6, { 1, 1, 1, 1 } }, -- White
        { 0.2, { 1, 0, 0, 1 } }, -- Red
        { 0.0, { 1, 0, 0, 0 } }  -- Transparent red
    },

    -- Ice particle color stops (ordered from t=1 to t=0)
    ice_colors = {
        { 1.0, { 0, 0, 0.8, 1 } }, -- Dark blue
        { 0.6, { 0, 0, 0.8, 1 } }, -- Dark blue
        { 0.2, { 0, 0.6, 1, 1 } }, -- Turkish blue
        { 0.0, { 0, 0.6, 1, 0 } }  -- Transparent turkish blue
    },

    -- Fire particle animation
    fire_animation = {
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
        pixel_size = 2
    },

    -- Ice particle animation
    ice_animation = {
        frames = {
            { -- Frame 1: Basic crystal
                { 0, 0, 1, 0, 0 },
                { 0, 1, 1, 1, 0 },
                { 1, 1, 0, 1, 1 },
                { 0, 1, 1, 1, 0 },
                { 0, 0, 1, 0, 0 }
            },
            { -- Frame 2: Sparkle top-right
                { 0, 0, 1, 1, 0 },
                { 0, 1, 1, 1, 0 },
                { 1, 1, 0, 1, 1 },
                { 0, 1, 1, 1, 0 },
                { 0, 0, 1, 0, 0 }
            },
            { -- Frame 3: Sparkle bottom-left
                { 0, 0, 1, 0, 0 },
                { 0, 1, 1, 1, 0 },
                { 1, 1, 0, 1, 1 },
                { 1, 1, 1, 1, 0 },
                { 0, 0, 1, 0, 0 }
            },
            { -- Frame 4: Crystal slightly rotated
                { 0, 1, 1, 0, 0 },
                { 0, 1, 1, 1, 0 },
                { 1, 1, 0, 1, 1 },
                { 0, 1, 1, 1, 0 },
                { 0, 0, 1, 1, 0 }
            }
        },
        frame_duration = 0.15, -- Slightly slower than fire
        pixel_size = 2
    }
}

return constants
