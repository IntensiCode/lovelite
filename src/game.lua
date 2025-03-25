-- Import modules
local camera = require("src.camera")
local map_manager = require("src.map_manager")
local debug = require("src.debug")
local player = require("src.player")
local projectiles = require("src.projectiles")
local particles = require("src.particles")

print("Game module loaded!")

-- Make game a global variable
_game = {
    camera = camera,
    map_manager = map_manager,
    debug = debug,
    player = player,
    projectiles = projectiles,
    particles = particles
}

function _game.load()
    print("Game load started!")
    
    -- Initialize camera
    _game.camera.load()
    
    -- Load map
    _game.map_manager.load()
    
    -- Initialize player
    _game.player.load()
end

function _game.update(dt)
    -- Update map
    _game.map_manager.map:update(dt)
    
    -- Update player
    _game.player.update(dt)
    
    -- Update camera
    _game.camera.update(dt)
    
    -- Update debug
    _game.debug.update(dt)
    
    _game.projectiles.update(dt)
    _game.particles.update(dt)
end

function _game.draw()
    -- Begin drawing to camera canvas
    _game.camera.beginDraw()
    
    -- Apply camera transform
    local translation = _game.camera.translation()
    love.graphics.translate(translation.x, translation.y)
    
    -- Draw map with camera translation
    _game.map_manager.map:draw(translation.x, translation.y)
    
    -- Draw player
    _game.player.draw()
    
    -- Draw walls that should appear above player
    _game.map_manager.draw_walls_above_player(_game.player.pos)
    
    -- Draw projectiles
    _game.projectiles.draw()
    
    -- Draw particles
    _game.particles.draw()
    
    -- Undo camera transform for debug overlay
    love.graphics.translate(-translation.x, -translation.y)
    
    -- Draw UI elements (in screen space)
    _game.player.draw_ui()

    -- Draw debug info
    _game.debug.draw()
    
    -- End drawing to camera canvas and draw it to screen
    _game.camera.endDraw()
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