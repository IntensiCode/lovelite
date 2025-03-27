local t = require("src.base.table")

---@class Weapon
---@field name string
---@field damage number
---@field cooldown number
---@field speed number
---@field initial boolean
---@field tile table
local weapons = {
    fist = {
        name = "fist",
        melee = 5,
        cooldown = 0.3,
        speed = 1.0,
        initial = true
    },
    bite = {
        name = "bite",
        melee = 5,
        cooldown = 0.6,
        speed = 1.0,
        initial = true
    },
    sonic = {
        name = "sonic",
        damage = 10,
        cooldown = 1.0,
        speed = 1.0,
        initial = true
    },
    strongsonic = {
        name = "strongsonic",
        damage = 25,
        cooldown = 2.5,
        speed = 1.0,
        initial = true
    }
}

---Initialize weapons from map manager
---@param dungeon table The map manager instance
function weapons.init(dungeon)
    -- Add all weapons from map manager
    for gid, weapon_props in pairs(dungeon.weapons) do
        local weapon = t.clone(weapon_props)
        weapon.tile = weapon_props.tile
        weapons[weapon.name] = weapon
    end
end

return weapons 