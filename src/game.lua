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
    collision = collision
}

function _game.load()
    _game.camera.load()
    _game.dungeon.load()
    _game.collision.load()
    _game.pathfinder.load()
    _game.debug.load()
    _game.player.load()
    _game.collectibles.load()
    _game.enemies.load()
    _game.sound.load()

    -- No loading for projectiles and particles
    -- _game.projectiles.load()
    -- _game.particles.load()
end

function _game.update(dt)
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

    _game.camera.endDraw()
end

---Find all positions that need wall checking
---@return Vector2[] List of positions that need wall checking
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
    if key == "escape" then
        love.event.quit()
    elseif key == "d" then
        _game.debug.toggle()
    end
end

-- Handle window resize
function _game.resize(w, h)
    _game.camera.resize(w, h)
end

return _game
