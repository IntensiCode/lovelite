-- Import modules
local camera = require("src.camera")
local map_manager = require("src.map_manager")
local debug = require("src.debug")
local player = require("src.player")
local projectiles = require("src.projectiles")
local particles = require("src.particles")
local collectibles = require("src.collectibles")
local enemies = require("src.enemies")

print("Game module loaded!")

-- Make game a global variable
_game = {
    camera = camera,
    map_manager = map_manager,
    debug = debug,
    player = player,
    projectiles = projectiles,
    particles = particles,
    collectibles = collectibles,
    enemies = enemies
}

function _game.load()
    _game.camera.load()
    _game.map_manager.load()
    _game.player.load()
    _game.collectibles.load()
    _game.enemies.load()

    -- No loading for projectiles and particles
end

function _game.update(dt)
    _game.map_manager.map:update(dt)
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

    _game.map_manager.map:draw(translation.x, translation.y)

    _game.collectibles.draw()
    _game.player.draw()
    _game.projectiles.draw()
    _game.enemies.draw()

    -- Find and draw all overlapping tiles
    local positions = _game.find_overlappable_positions()
    local overlapping_tiles = _game.map_manager.find_overlapping_tiles(positions)
    _game.map_manager.draw_overlapping_tiles(overlapping_tiles)

    -- Draw particles above the redrawn wall tiles
    _game.particles.draw()

    love.graphics.translate(-translation.x, -translation.y)

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
