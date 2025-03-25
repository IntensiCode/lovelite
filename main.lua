print("Main module started!")

-- Add src directory to the Lua path
love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. love.filesystem.getRequirePath())

-- Load the game module
local game = require("game")

-- Forward LÖVE callbacks to the game module
function love.load()
    if game.load then game.load() end
end

function love.update(dt)
    if game.update then game.update(dt) end
end

function love.draw()
    if game.draw then game.draw() end
end

function love.keypressed(key)
    if game.keypressed then game.keypressed(key) end
end

function love.resize(w, h)
    if game.resize then game.resize(w, h) end
end 