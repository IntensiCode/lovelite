print("Main module started!")

-- Add src directory to the Lua path
love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. love.filesystem.getRequirePath())

local font = require("src.base.font")
local screen = require("src.base.screen")
local title = require("src.title")
local game = require("src.game")
local argparse = require("src.libraries.argparse")

function love.load()
    -- Parse command line arguments
    local parser = argparse("love-test", "A roguelike game.")
    parser:argument("game_folder", "Game folder. Usually just the '.'.")
    parser:flag("--dev", "Start in development mode (skip title screen).")
    local args = parser:parse()

    -- Load global resources first
    font.load()

    screen.register("title", title)
    screen.register("game", game)

    -- Initialize with title screen or game screen based on dev flag
    screen.switch_to(args.dev and "game" or "title")
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
    -- Forward to current screen
    local current_screen = screen.get_current()
    current_screen.keypressed(key)
end

function love.resize(w, h)
    local current_screen = screen.get_current()
    current_screen.resize(w, h)
end
