local game = {
    blink_timer = 0,
    blink_visible = true,
    initialized = false,
    space_shortcut_registered = false, -- Flag to track if space shortcut is registered
}

function game.exit_to_title()
    if DI.fade.on_fade_done then
        return
    end
    DI.fade.on_fade_done = function()
        DI.screen.switch_to("title")
    end
    DI.fade.reset("fade_out", 0.2)
end

function game.register_shortcuts()
    DI.keys.add_shortcut("escape", {
        callback = function()
            game.exit_to_title()
        end,
        description = "Exit to title screen",
        scope = "game",
    })

    DI.keys.add_shortcut("kp0", {
        callback = function()
            DI.debug.toggle()
        end,
        description = "Toggle debug overlay",
        scope = "game",
    })

    DI.keys.add_shortcut("`", {
        callback = function()
            DI.debug_console:toggle()
        end,
        description = "Toggle debug console",
        scope = "game",
    })
end

-- Set space shortcut for exiting when player is dead
function game.set_space_for_exit(enabled)
    if enabled and not game.space_shortcut_registered then
        DI.keys.add_shortcut("space", {
            callback = function()
                game.exit_to_title()
            end,
            description = "Continue when dead",
            scope = "game",
        })
        game.space_shortcut_registered = true
    elseif not enabled and game.space_shortcut_registered then
        DI.keys.remove_shortcut_by_key("space")
        game.space_shortcut_registered = false
    end
end

function game.unregister_shortcuts()
    DI.keys.remove_shortcuts_by_scope("game")
    game.space_shortcut_registered = false
end

function game.attach()
    game.register_shortcuts()
    DI.fog_of_war.attach()
end

function game.detach()
    game.unregister_shortcuts()
    DI.fog_of_war.detach()
end

---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function game.load(opts)
    opts = opts or { reset = true }

    if not game.initialized then
        -- Note that some modules are already loaded in main.lua
        DI.dungeon = require("src.map.dungeon")
        DI.fade = require("src.base.fade")
        DI.pathfinder = require("src.pathfinder")
        DI.player = require("src.player")
        DI.projectiles = require("src.projectiles")
        DI.particles = require("src.particles")
        DI.collectibles = require("src.collectibles")
        DI.enemies = require("src.enemies")
        DI.sound = require("src.sound")
        DI.collision = require("src.map.collision")
        DI.decals = require("src.decals")
        DI.weapons = require("src.enemy.weapons")
        DI.positions = require("src.base.positions")
        DI.fog_of_war = require("src.map.fog_of_war")
        DI.player_hud = require("src.player_hud")
        DI.walls = require("src.map.walls")

        game.initialized = true
    end

    DI.camera.load(opts)
    DI.dungeon.load(opts)
    DI.weapons.load()
    DI.collision.load(opts)
    DI.pathfinder.load(opts)
    DI.player.load(opts)
    DI.collectibles.load(opts)
    DI.enemies.load(opts)
    DI.sound.load(opts)
    DI.decals.load()

    DI.fog_of_war.load(opts)

    DI.fade.on_fade_done = nil
    DI.fade.reset("fade_in", 0.2)

    game.update_blink_timer(0)
end

---Update the blink timer state
---@param dt number Delta time
function game.update_blink_timer(dt)
    game.blink_timer = game.blink_timer + dt
    if game.blink_visible and game.blink_timer >= 0.8 then
        game.blink_visible = false
        game.blink_timer = 0
    elseif not game.blink_visible and game.blink_timer >= 0.2 then
        game.blink_visible = true
        game.blink_timer = 0
    end
end

local function update_space_key()
    local is_player_dead = DI.player.is_dead
        and (DI.player.death_time == nil or DI.player.death_time <= 0)
    game.set_space_for_exit(is_player_dead)
end

function game.update(dt)
    -- Update fade
    DI.fade.update(dt)

    -- Update blink timer
    game.update_blink_timer(dt)

    -- Update space key based on player state
    update_space_key()

    DI.dungeon.map:update(dt)
    DI.player.update(dt)
    DI.camera.update(dt)
    DI.projectiles.update(dt)
    DI.particles.update(dt)
    DI.collectibles.update(dt)
    DI.enemies.update(dt)
    DI.fog_of_war.update(dt)
end

function game.draw()
    DI.camera.beginDraw()

    local translation = DI.camera.translation()
    love.graphics.translate(translation.x, translation.y)

    -- First phase: Draw base map
    DI.dungeon.draw_map(translation.x, translation.y)

    if DI.debug.enabled then
        DI.pathfinder.draw()
    end

    -- Draw decals below everything
    DI.decals.draw()

    -- Draw in correct order
    DI.player.draw()
    DI.collectibles.draw()
    DI.enemies.draw()
    DI.projectiles.draw()

    -- Second phase: Draw overlaps
    DI.dungeon.draw_overlaps(translation.x, translation.y)

    -- Draw particles above the redrawn wall tiles
    DI.particles.draw()

    -- Draw fog of war on top of everything except UI
    DI.fog_of_war.draw(translation.x, translation.y)

    -- Draw debug positions in world space
    if DI.debug.enabled then
        DI.debug.draw_entity_positions()
    end

    -- Reset graphics
    love.graphics.translate(-translation.x, -translation.y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.origin()
    love.graphics.setBlendMode("alpha")

    -- Draw UI elements
    DI.player_hud.draw()
    DI.debug.draw()
    DI.fog_of_war.draw_debug_grid()
    DI.debug_console:draw()

    -- Draw game over overlay if player is dead
    if
        DI.player.is_dead
        and (DI.player.death_time == nil or DI.player.death_time <= 0)
    then
        game.draw_game_over_overlay()
    end

    -- Draw fade overlay last
    DI.fade.draw(DI.camera.width, DI.camera.height)

    DI.camera.endDraw()
end

---Draw the game over overlay
function game.draw_game_over_overlay()
    -- Semi-transparent black background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, DI.camera.width, DI.camera.height)

    -- Reset color for text
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw "GAME OVER" and "YOU DIED"
    DI.font.draw_text(
        "GAME OVER",
        DI.camera.width / 2,
        DI.camera.height / 2 - 80,
        DI.font.anchor.center
    )
    DI.font.draw_text(
        "YOU DIED",
        DI.camera.width / 2,
        DI.camera.height / 2 - 60,
        DI.font.anchor.center
    )

    -- Draw "Press SPACE to continue" at the bottom (only when visible)
    if game.blink_visible then
        DI.font.draw_text(
            "Press SPACE to continue",
            DI.camera.width / 2,
            DI.camera.height - 8,
            DI.font.anchor.bottom_center
        )
    end
end

---Find all positions that need wall checking
---@return pos[] List of positions that need wall checking
function game.find_overlappable_positions()
    local positions = { DI.player.pos }

    -- Add collectible positions
    for _, item in ipairs(DI.collectibles.items) do
        table.insert(positions, item.pos)
    end

    -- Add projectile positions
    for _, proj in ipairs(DI.projectiles.active) do
        table.insert(positions, proj.pos)
    end

    return positions
end

-- Handle window resize
function game.resize(w, h)
    DI.camera.resize(w, h)
end

return game
