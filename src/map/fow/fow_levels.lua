-- FOW Levels Module
-- Defines visibility levels for the fog of war system.
-- Provides constants for different fog densities from fully hidden to fully visible.

---@class FowLevels
---@field HIDDEN_0 number Fully hidden/black (0% visibility)
---@field HEAVY_FOG_1 number Heavy fog (25% visibility)
---@field MEDIUM_FOG_2 number Medium fog (50% visibility)
---@field LIGHT_FOG_3 number Light fog (75% visibility)
---@field VISIBLE_4 number Fully visible/transparent (100% visibility)
local fow_levels = {
    HIDDEN_0 = 0, -- Fully hidden/black
    HEAVY_FOG_1 = 1, -- 75% fog
    MEDIUM_FOG_2 = 2, -- 50% fog
    LIGHT_FOG_3 = 3, -- 25% fog
    VISIBLE_4 = 4, -- Fully visible/transparent
}

return fow_levels
