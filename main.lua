print("Main module started!")

-- Add src directory to the Lua path
love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. love.filesystem.getRequirePath())

local font = require("src.base.font")
local screen = require("src.base.screen")
local title = require("src.title")
local game = require("src.game")

function love.load()
    -- Load global resources first
    font.load()

    screen.register("title", title)
    screen.register("game", game)

    title.load()
    game.load()
end

function love.update(dt)
    local current_screen = screen.get_current()
    current_screen.update(dt)
end

function love.draw()
    local current_screen = screen.get_current()
    current_screen.draw()
end

function love.keypressed(key)
    -- Handle global keys first
    if key == "escape" then
        love.event.quit()
        return
    end

    -- Then forward to current screen
    local current_screen = screen.get_current()
    current_screen.keypressed(key)
end

function love.resize(w, h)
    local current_screen = screen.get_current()
    current_screen.resize(w, h)
end
