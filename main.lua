-- Add src directory to the Lua path
love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. love.filesystem.getRequirePath())

-- Extend standard libraries once for the entire game
require("src.base.math")
require("src.base.table")
require("src.base.log")

log.info("Main module started!")

local font = require("src.base.font")
local screen = require("src.base.screen")
local title = require("src.title")
local game = require("src.game")
local debug = require("src.base.debug")
local argparse = require("src.libraries.argparse")

function love.load()
    -- Parse command line arguments
    local parser = argparse("love-test", "A roguelike game.")
    parser:argument("game_folder", "Game folder. Usually just the '.'.")
    parser:flag("--dev", "Start in development mode (skip title screen).")
    parser:flag("--debug", "Enable debug mode.")
    parser:flag("--test", "Run tests instead of the game.")
    local args = parser:parse()

    -- Set log.dev flag from dev arg
    log.dev = args.dev

    -- Set log level based on command line flags
    if args.test then
        -- Always show at least INFO level for tests
        log.set_level(args.debug and log.LEVELS.DEBUG or log.LEVELS.INFO)
    elseif args.dev and args.debug then
        log.set_level(log.LEVELS.DEBUG)
    elseif args.dev then
        log.set_level(log.LEVELS.INFO)
    else
        log.set_level(log.LEVELS.WARN)
    end

    -- Set debug state based on flag
    debug.enabled = args.debug

    -- If in test mode, run the tests and quit
    if args.test then
        local test_runner = require("src.test.run_tests_love")
        local success = test_runner.run()
        love.event.quit(success and 0 or 1)
        return
    end

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
    -- Handle global keypresses
    if key == "d" then
        debug.toggle()
        return
    end

    -- Forward to current screen
    local current_screen = screen.get_current()
    current_screen.keypressed(key)
end

function love.resize(w, h)
    local current_screen = screen.get_current()
    current_screen.resize(w, h)
end
