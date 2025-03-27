-- Import modules
local camera = require("src.camera")
local dungeon = require("src.map.dungeon")
local pathfinder = require("src.pathfinder")
local debug = require("src.base.debug")
local player = require("src.player")
local projectiles = require("src.projectiles")
local particles = require("src.particles")
local collectibles = require("src.collectibles")
local enemies = require("src.enemies")
local sound = require("src.sound")
local collision = require("src.map.collision")
local fade = require("src.base.fade")
local screen = require("src.base.screen")
local font = require("src.base.font")

-- Make game a global variable
_game = {
    camera = camera,
    dungeon = dungeon,
    pathfinder = pathfinder,
    debug = debug,
    player = player,
    projectiles = projectiles,
    particles = particles,
    collectibles = collectibles,
    enemies = enemies,
    sound = sound,
    collision = collision,
    font = font,
    blink_timer = 0,
    blink_visible = true
}

---Load the game module
---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function _game.load(opts)
    opts = opts or { reset = true }

    _game.camera.load(opts)
    _game.dungeon.load(opts)
    _game.collision.load(opts)
    _game.pathfinder.load(opts)
    _game.player.load(opts)
    _game.collectibles.load(opts)
    _game.enemies.load(opts)
    _game.sound.load(opts)
    _game.font.load() -- Load fonts before using them

    -- Start with fade in
    fade.on_fade_done = nil
    fade.reset("fade_in", 0.2)

    -- No loading for projectiles and particles
    -- _game.projectiles.load()
    -- _game.particles.load()
end

---Update the blink timer state
---@param dt number Delta time
function _game.update_blink_timer(dt)
    _game.blink_timer = _game.blink_timer + dt
    if _game.blink_visible and _game.blink_timer >= 0.8 then
        _game.blink_visible = false
        _game.blink_timer = 0
    elseif not _game.blink_visible and _game.blink_timer >= 0.2 then
        _game.blink_visible = true
        _game.blink_timer = 0
    end
end

function _game.update(dt)
    -- Update fade
    fade.update(dt)

    -- Update blink timer
    _game.update_blink_timer(dt)

    _game.dungeon.map:update(dt)
    _game.player.update(dt)
    _game.camera.update(dt)
    _game.debug.update(dt)
    _game.projectiles.update(dt)
    _game.particles.update(dt)
    _game.collectibles.update(dt)
    _game.enemies.update(dt)
end

function _game.draw()
    _game.camera.beginDraw()

    local translation = _game.camera.translation()
    love.graphics.translate(translation.x, translation.y)

    _game.dungeon.map:draw(translation.x, translation.y)
    if _game.debug.enabled then
        _game.pathfinder.draw()
    end

    -- Draw in correct order
    _game.player.draw()
    _game.collectibles.draw()
    _game.enemies.draw()
    _game.projectiles.draw()

    -- Find and draw all overlapping tiles
    local positions = _game.find_overlappable_positions()
    local overlapping_tiles = _game.collision.find_overlapping_tiles(positions)
    _game.collision.draw_overlapping_tiles(overlapping_tiles)

    -- Draw particles above the redrawn wall tiles
    _game.particles.draw()

    -- Draw debug positions in world space
    if _game.debug.enabled then
        _game.debug.draw_entity_positions()
    end

    -- Reset graphics
    love.graphics.translate(-translation.x, -translation.y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.origin()
    love.graphics.setBlendMode("alpha")

    -- Draw UI elements
    _game.player.draw_ui()
    _game.debug.draw()

    -- Draw game over overlay if player is dead
    if _game.player.is_dead and (_game.player.death_time == nil or _game.player.death_time <= 0) then
        _game.draw_game_over_overlay()
    end

    -- Draw fade overlay last
    fade.draw(_game.camera.width, _game.camera.height)

    _game.camera.endDraw()
end

---Draw the game over overlay
function _game.draw_game_over_overlay()
    -- Semi-transparent black background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, _game.camera.width, _game.camera.height)

    -- Reset color for text
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw "GAME OVER" and "YOU DIED"
    _game.font.draw_text("GAME OVER", _game.camera.width / 2, _game.camera.height / 2 - 80, _game.font.anchor.center)
    _game.font.draw_text("YOU DIED", _game.camera.width / 2, _game.camera.height / 2 - 60, _game.font.anchor.center)

    -- Draw "Press SPACE to continue" at the bottom (only when visible)
    if _game.blink_visible then
        _game.font.draw_text("Press SPACE to continue", _game.camera.width / 2, _game.camera.height - 8,
        _game.font.anchor.bottom_center)
    end
end

---Find all positions that need wall checking
---@return pos[] List of positions that need wall checking
function _game.find_overlappable_positions()
    local positions = { _game.player.pos }

    -- Add collectible positions
    for _, item in ipairs(_game.collectibles.items) do
        table.insert(positions, item.pos)
    end

    -- Add projectile positions
    for _, proj in ipairs(_game.projectiles.active) do
        table.insert(positions, proj.pos)
    end

    return positions
end

function _game.keypressed(key)
    if key == "d" then
        _game.debug.toggle()
    elseif key == "escape" then
        -- Fade out and return to title screen
        fade.on_fade_done = function()
            screen.switch_to("title")
        end
        fade.reset("fade_out", 0.2)
    elseif key == "space" and _game.player.is_dead and (_game.player.death_time == nil or _game.player.death_time <= 0) then
        -- Fade out and return to title screen when dead
        fade.on_fade_done = function()
            screen.switch_to("title")
        end
        fade.reset("fade_out", 0.2)
    end
end

-- Handle window resize
function _game.resize(w, h)
    _game.camera.resize(w, h)
end

return _game
