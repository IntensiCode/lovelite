love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. love.filesystem.getRequirePath())

require("src.base.di")
require("src.base.math")
require("src.base.log")
require("src.base.table")
require("src.base.list")

local function init_di(debug_mode)
    log.info("Initializing DI system")

    DI.lg = love.graphics
    DI.camera = require("src.base.camera")
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

local function init_game(dev_mode)
    log.info("Initializing game in " .. (dev_mode and "dev" or "prod") .. " mode")

    DI.camera.load()
    DI.font.load()
    DI.keys.load()
    DI.screen.load()

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
    parser:option("--test", [[Run tests instead of the game.
Optionally specify one or more test files separated by
commas (e.g., --test=test_pos,test_keys).
Optionally specify a single test case for a file by
using <filename:test_name> instead of just <filename>.
Omit the test/ prefix and the .lua suffix for
filenames.]])
        :args("?")
    parser:option("--screenshot", "Take a screenshot after specified seconds and save to test.png.")
        :args("?")
        :convert(tonumber)
    parser:option("--auto-quit", "Quit the game after specified seconds.")
        :args(1) -- Require exactly one argument
        :convert(tonumber)
    return parser
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

local function run_tests_and_quit(args, parser)
    log.dev = true -- To make log.assert fail
    local runner = require("test")
    runner.parse_test_option(args.test)
    if (runner.invalid_spec()) then
        log.error("Invalid test option arguments\n")
        print(parser:get_help())
        love.event.quit(1)
        return
    end
    local success = runner.run()
    love.event.quit(success and 0 or 1)
end

function love.load()
    local parser = parse_args()
    local args = parser:parse()
    set_log_level(args)
    log.dev = args.dev

    if args.test then
        run_tests_and_quit(args, parser)
        return
    end

    init_di(args.debug)
    init_game(args.dev)

    -- Set up screenshot timer if requested
    if args.screenshot then
        local screenshot = require("src.base.screenshot")
        local delay = tonumber(args.screenshot) or 1
        screenshot.schedule(delay, "test.png")
    end

    -- Set up auto-quit timer if requested
    if args.auto_quit then
        local auto_quit = require("src.base.auto_quit")
        local delay = tonumber(args.auto_quit)
        -- The auto_quit module handles invalid delay checks
        auto_quit.schedule(delay)
    end
end
