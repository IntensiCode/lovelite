-- Import modules
local camera = require("src.camera")
local dungeon = require("src.map.dungeon")
local pathfinder = require("src.pathfinder")
local debug = require("src.base.debug")
local player = require("src.player")
local player_hud = require("src.player_hud")
local projectiles = require("src.projectiles")
local particles = require("src.particles")
local collectibles = require("src.collectibles")
local enemies = require("src.enemies")
local sound = require("src.sound")
local collision = require("src.map.collision")
local fade = require("src.base.fade")
local screen = require("src.base.screen")
local font = require("src.base.font")
local decals = require("src.decals")

local game = {
    blink_timer = 0,
    blink_visible = true,
    initialized = false
}

---Load the game screen
---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function game.load(opts)
    opts = opts or { reset = true }

    -- Initialize components into DI if not already done
    if not game.initialized then
        DI.camera = camera
        DI.dungeon = dungeon
        DI.pathfinder = pathfinder
        DI.debug = debug
        DI.player = player
        DI.projectiles = projectiles
        DI.particles = particles
        DI.collectibles = collectibles
        DI.enemies = enemies
        DI.sound = sound
        DI.collision = collision
        DI.font = font
        DI.decals = decals
        game.initialized = true
    end

    DI.camera.load(opts)
    DI.dungeon.load(opts)
    DI.collision.load(opts)
    DI.pathfinder.load(opts)
    DI.player.load(opts)
    DI.collectibles.load(opts)
    DI.enemies.load(opts)
    DI.sound.load(opts)
    DI.font.load() -- Load fonts before using them

    -- Start with fade in
    fade.on_fade_done = nil
    fade.reset("fade_in", 0.2)
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

function game.update(dt)
    -- Update fade
    fade.update(dt)

    -- Update blink timer
    game.update_blink_timer(dt)

    DI.dungeon.map:update(dt)
    DI.player.update(dt)
    DI.camera.update(dt)
    DI.debug.update(dt)
    DI.projectiles.update(dt)
    DI.particles.update(dt)
    DI.collectibles.update(dt)
    DI.enemies.update(dt)
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
    player_hud.draw()
    DI.debug.draw()

    -- Draw game over overlay if player is dead
    if DI.player.is_dead and (DI.player.death_time == nil or DI.player.death_time <= 0) then
        game.draw_game_over_overlay()
    end

    -- Draw fade overlay last
    fade.draw(DI.camera.width, DI.camera.height)

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
    DI.font.draw_text("GAME OVER", DI.camera.width / 2, DI.camera.height / 2 - 80, DI.font.anchor.center)
    DI.font.draw_text("YOU DIED", DI.camera.width / 2, DI.camera.height / 2 - 60, DI.font.anchor.center)

    -- Draw "Press SPACE to continue" at the bottom (only when visible)
    if game.blink_visible then
        DI.font.draw_text("Press SPACE to continue", DI.camera.width / 2, DI.camera.height - 8,
        DI.font.anchor.bottom_center)
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

function game.keypressed(key)
    if key == "d" then
        DI.debug.toggle()
    elseif key == "escape" then
        -- Fade out and return to title screen
        fade.on_fade_done = function()
            screen.switch_to("title")
        end
        fade.reset("fade_out", 0.2)
    elseif key == "space" and DI.player.is_dead and (DI.player.death_time == nil or DI.player.death_time <= 0) then
        -- Fade out and return to title screen when dead
        fade.on_fade_done = function()
            screen.switch_to("title")
        end
        fade.reset("fade_out", 0.2)
    end
end

-- Handle window resize
function game.resize(w, h)
    DI.camera.resize(w, h)
end

return game 