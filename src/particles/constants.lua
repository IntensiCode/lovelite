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
    lightning_drift_speed = 0.1  -- How fast lightning particles drift horizontally
}

return constants 