-- Magic particle settings
local constants = {
    -- Magic settings
    magic_count = 6,  -- Number of particles per magic effect
    magic_speed = 1,  -- Base upward speed for magic particles
    magic_size = 3,   -- Size of magic particles in pixels
    magic_life = 0.8,  -- Life in seconds for magic particles
    magic_spread = 0.3,  -- Horizontal spread for magic particles
    
    -- Lightning specific settings
    lightning_delay_max = 0.1,  -- Maximum random delay for lightning strikes
    lightning_drift_speed = 0.1,  -- How fast lightning particles drift horizontally

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
}

return constants 