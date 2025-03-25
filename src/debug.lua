local debug = {
    enabled = true
}

-- Helper function to print a table's contents
local function print_table(tbl, indent)
    indent = indent or ""
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(indent .. k .. " = {")
            print_table(v, indent .. "  ")
            print(indent .. "}")
        else
            print(indent .. k .. " = " .. tostring(v))
        end
    end
end

-- Helper function to dump a collection of tiles
local function dump_tiles(kind, which)
    print("\n" .. kind .. ":")
    for gid, data in pairs(which) do
        print(string.format("Tile ID %d:", gid))
        print_table(data, "  ")
    end
end

function debug.update(dt)
    if not debug.enabled then return end
    
    -- Debug print player info
    -- print("Player object:", _game.player)
    -- print("Player position:", _game.player.pos)
end

function debug.draw()
    if not debug.enabled then return end
    
    -- Draw debug text
    love.graphics.setColor(1, 1, 1, 1)
    local info = {
        string.format("Player: %.1f, %.1f", _game.player.pos.x, _game.player.pos.y),
        string.format("Camera: %.1f, %.1f", _game.camera.world_pos.x, _game.camera.world_pos.y),
        string.format("Scale: %.2f", _game.camera.scale),
        string.format("FPS: %d", love.timer.getFPS())
    }
    
    for i, text in ipairs(info) do
        love.graphics.print(text, 10, 10 + (i-1) * 20)
    end
end

function debug.print_map_tiles()
    print("\nProcessed tiles:")
    
    dump_tiles("Enemies", _game.map_manager.enemies)
    dump_tiles("Weapons", _game.map_manager.weapons)
    dump_tiles("Shields", _game.map_manager.shields)
    
    print("\nChest animation frames:")
    for frame, gid in ipairs(_game.map_manager.chest_anim) do
        print(string.format("Frame %d: Tile ID %d", frame-1, gid))
    end
end

function debug.toggle()
    debug.enabled = not debug.enabled
end

-- Add debug to global game variable when loaded
_game = _game or {}
_game.debug = debug

return debug 