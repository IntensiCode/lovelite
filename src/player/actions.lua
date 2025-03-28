local events = require("src.base.events")

local actions = {}

---Handle player shooting
---@param player table The player object
function actions.handle_shooting(player)
    local shoot = love.keyboard.isDown("space") or love.keyboard.isDown("z")
        or love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

    if not shoot or not player.weapon then
        return
    end

    -- Check if weapon is on cooldown
    if player.cooldown > 0 then
        return
    end

    -- Set cooldown and spawn projectile via event
    player.cooldown = player.weapon.cooldown
    events.send("projectile.spawn", {
        pos = player.pos,
        direction = player.last_direction,
        weapon = player.weapon
    })
end

---Handle collection of items (weapons, shields, etc.)
---@param player table The player object
function actions.handle_collecting(player)
    local collected = DI.collectibles.check_collection(player.pos)
    if not collected then
        return
    elseif collected.weapon then
        -- Store reference to the collected weapon
        player.weapon = collected.weapon
        -- Reset cooldown when switching weapons
        player.cooldown = 0
    elseif collected.shield then
        -- Store reference to the collected shield
        player.shield = collected.shield
    end
end

return actions 