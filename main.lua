love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. love.filesystem.getRequirePath())

require("src.base.di")
require("src.base.math")
require("src.base.log")
require("src.base.table")

local function init_di(debug_mode)
    log.info("Initializing DI system")

    DI.lg = love.graphics
    DI.font = require("src.base.font")
    DI.fade = require("src.base.fade")
    DI.screen = require("src.base.screen")
    DI.title = require("src.title")
    DI.game = require("src.game")
    DI.debug = require("src.base.debug")
    DI.debug_console = require("src.base.debug_console")
    DI.debug_commands = require("src.base.debug_commands")
    DI.keys = require("src.base.keys")

    DI.debug.enabled = debug_mode
end

local function setup_global_shortcuts()
    DI.keys.add("`", function() DI.debug_console:toggle() end, nil, "Toggle debug console")
end

local function init_game(dev_mode)
    log.info("Initializing game in " .. (dev_mode and "dev" or "prod") .. " mode")

    DI.font.load()
    DI.keys.load()
    DI.screen.load()

    setup_global_shortcuts()

    DI.screen.register("title", DI.title)
    DI.screen.register("game", DI.game)
    DI.screen.switch_to(dev_mode and "game" or "title")
end

local function parse_args()
    local argparse = require("src.libraries.argparse")
    local parser = argparse("love-test", "A roguelike game.")
    parser:argument("game_folder", "Game folder. Usually just the '.'.")
    parser:flag("--dev", "Start in development mode (skip title screen).")
    parser:flag("--debug", "Enable debug mode.")
    parser:flag("--test", "Run tests instead of the game.")
    return parser:parse()
end

local function set_log_level(args)
    if args.test then
        log.set_level(args.debug and log.LEVELS.DEBUG or log.LEVELS.INFO)
    elseif args.dev and args.debug then
        log.set_level(log.LEVELS.DEBUG)
    elseif args.dev then
        log.set_level(log.LEVELS.INFO)
    else
        log.set_level(log.LEVELS.WARN)
    end
end

function love.load()
    local args = parse_args()
    set_log_level(args)
    log.dev = args.dev

    -- If in test mode, run the tests and quit
    if args.test then
        log.dev = true -- To make log.assert fail
        local test_runner = require("src.test.run_tests_love")
        local success = test_runner.run()
        love.event.quit(success and 0 or 1)
        return
    end

    init_di(args.debug)
    init_game(args.dev)
end
