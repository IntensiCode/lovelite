local t = require("src.base.table")

---@class Weapon
---@field name string
---@field damage number
---@field cooldown number
---@field speed number
---@field tile table?
---@field range number The range in tile units
local weapons = {
    fist = {
        name = "fist",
        melee = 5,
        cooldown = 0.3,
        speed = 1.0,
        range = 0.5
    },
    bite = {
        name = "bite",
        melee = 5,
        cooldown = 0.6,
        speed = 1.0,
        range = 0.5
    },
    strongbite = {
        name = "strongbite",
        melee = 15,
        cooldown = 0.6,
        speed = 1.0,
        range = 0.5
    },
    sonic = {
        name = "sonic",
        damage = 10,
        cooldown = 1.0,
        speed = 1.0,
        range = 8.0
    },
    strongsonic = {
        name = "strongsonic",
        damage = 25,
        cooldown = 2.5,
        speed = 1.0,
        range = 8.0
    },
    web = {
        web = true, -- To make projectiles.spawn_hit_particles work
        name = "web",
        damage = 1,
        cooldown = 1.0,
        speed = 2.0,
        range = 5.0
    }
}

---Initialize weapons from map manager
function weapons.load()
    print("Initializing weapons")
    -- Add all weapons from map manager
    for gid, weapon_props in pairs(DI.dungeon.weapons) do
        local weapon = t.clone(weapon_props)
        -- weapon.tile = weapon_props.tile
        -- Set default range based on weapon type
        if not weapon.range then
            if weapon.fire or weapon.ice or weapon.lightning then
                weapon.range = 8.0
            else
                weapon.range = 0.5 -- Default to melee range
            end
        end
        weapons[weapon.name] = weapon
    end
    t.print_keys(weapons, "  ")
end

return weapons 