local pos = require("src.base.pos")
local dmg = require("src.player.damage")
local m = require("src.player.movement")
local d = require("src.player.draw")
local pf = require("src.player.pathfinding")
local a = require("src.player.actions")
local p = require("src.particles")

---@class Player
---@field pos pos
---@field tile_id number
---@field tile table
---@field speed number
---@field hitpoints number
---@field max_hitpoints number
---@field weapon table
---@field shield table
---@field tile_size number
---@field last_direction pos
---@field cooldown number
---@field armorclass number
---@field is_dead boolean
---@field death_time number|nil Time remaining in death animation
---@field stun_time number|nil Time remaining in stun effect
---@field slow_time number|nil Time remaining in slow effect
---@field slow_factor number|nil Speed multiplier during slow effect
local player = {
    pos = pos.new(0, 0),
    tile_id = nil,
    tile = nil,
    speed = 5, -- tiles per second
    hitpoints = 100,
    max_hitpoints = 100,
    is_dead = false,
    death_time = nil,
    weapon = nil,
    shield = nil,
    tile_size = nil,
    last_direction = pos.new(1, 0), -- Default facing right
    cooldown = 0,                   -- Initialize cooldown to 0
    armorclass = 0,                 -- Base armor class
    stun_time = nil,                -- Time remaining in stun effect
    slow_time = nil,                -- Time remaining in slow effect
    slow_factor = 0.5               -- Speed multiplier during slow effect
}

function player.on_hit(weapon)
    dmg.on_hit(player, weapon)

    -- Handle web effects
    if weapon.web then
        -- Apply stun
        player.stun_time = 0.2
        -- Apply slow
        player.slow_time = 0.5
        -- Spawn web decal
        DI.decals.spawn("web", player.pos)
    end

    -- Handle melee effects
    if weapon.melee then
        -- Spawn dust particles at attack location
        p.spawn({
            pos = player.pos, -- Position is already centered
            kind = "dust"
        })
    end
end

---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function player.load(opts)
    opts = opts or { reset = true }

    if opts.reset then
        -- Reset all player state
        local start = DI.dungeon.get_player_start_position()

        player.pos = start.pos
        player.tile = start.tile
        player.tile_id = start.tile.id

        local setup = DI.dungeon.player
        player.speed = setup.speed
        player.armorclass = setup.armorclass
        -- Set lower hitpoints in debug mode
        if DI.debug.enabled then
            player.hitpoints = 5
        else
            player.hitpoints = setup.hitpoints
        end
        player.max_hitpoints = setup.max_hitpoints

        -- Reset combat state
        player.is_dead = false
        player.death_time = nil
        player.cooldown = 0
        player.sonic_damage = nil
        player.last_tile = nil
        player.last_direction = pos.new(1, 0) -- Default facing right

        -- Reset equipment
        player.weapon = nil
        player.shield = nil

        -- Assign initial weapon if specified in dungeon setup
        if setup.weapon then
            for _, weapon in pairs(DI.dungeon.weapons) do
                if weapon.name == setup.weapon then
                    player.weapon = weapon
                    break
                end
            end
        end
    end

    -- Get tile size from tileset (this is constant and only needs to be set once)
    player.tile_size = DI.dungeon.tile_size

    -- Add player to global game variable
    DI.player = player
end

function player.update(dt)
    -- Handle death animation
    if player.is_dead then
        if player.death_time and player.death_time > 0 then
            player.death_time = player.death_time - dt
        end
        return
    end

    -- Handle stun time
    if player.stun_time and player.stun_time > 0 then
        player.stun_time = player.stun_time - dt
        if player.stun_time <= 0 then
            player.stun_time = nil
        end
        return
    end

    -- Handle slow time
    if player.slow_time and player.slow_time > 0 then
        player.slow_time = player.slow_time - dt
        if player.slow_time <= 0 then
            player.slow_time = nil
        end
    end

    -- Get movement input
    local input = m.get_input()

    -- Update last direction if moving
    if input.x ~= 0 or input.y ~= 0 then
        player.last_direction = input:normalized()
    end

    -- Store original movement for wall sliding
    local original_movement = pos.new(input.x, input.y)

    -- Normalize diagonal movement for the initial movement attempt
    if input.x ~= 0 and input.y ~= 0 then
        input = input * 0.7071 -- 1/sqrt(2), maintains consistent speed diagonally
    end

    -- Apply slow effect if active
    if player.slow_time then
        input = input * player.slow_factor
    end

    -- Handle movement
    m.handle(player, input, original_movement, dt)

    -- Update cooldown
    if player.cooldown > 0 then
        player.cooldown = player.cooldown - dt
    end

    -- Handle shooting
    a.handle_shooting(player)

    -- Check for collectibles
    a.handle_collecting(player)

    -- Get current tile position (floored)
    local current_tile = pos.new(
        math.floor(player.pos.x),
        math.floor(player.pos.y)
    )

    -- Check tile position changes
    pf.check_tile_position_change(player, current_tile)

    -- Handle sonic damage
    dmg.handle_sonic_damage(player, dt)
end

function player.draw()
    d.player(player)
end

return player
