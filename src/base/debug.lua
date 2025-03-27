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

---Draw red dots above all entity positions
function debug.draw_entity_positions()
    local tile_width = _game.map_manager.map.tilewidth
    local tile_height = _game.map_manager.map.tileheight

    -- Draw player position dot and text in dark blue
    love.graphics.setColor(0, 0, 0.8, 1) -- Dark blue
    local player_screen_x = (_game.player.pos.x - 1) * tile_width
    local player_screen_y = (_game.player.pos.y - 1) * tile_height
    love.graphics.circle("fill", player_screen_x, player_screen_y, 3)
    love.graphics.print(string.format("%.2f, %.2f", _game.player.pos.x, _game.player.pos.y),
        player_screen_x + 5, player_screen_y - 10)

    -- Draw enemy position dots in red
    love.graphics.setColor(1, 0, 0, 1)
    for _, enemy in ipairs(_game.enemies.items) do
        local enemy_screen_x = (enemy.pos.x - 1) * tile_width
        local enemy_screen_y = (enemy.pos.y - 1) * tile_height
        love.graphics.circle("fill", enemy_screen_x, enemy_screen_y, 3)
    end
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
        love.graphics.print(text, 10, 10 + (i - 1) * 20)
    end
end

function debug.print_map_tiles()
    print("\nProcessed tiles:")

    dump_tiles("Enemies", _game.map_manager.enemies)
    dump_tiles("Weapons", _game.map_manager.weapons)
    dump_tiles("Shields", _game.map_manager.shields)

    print("\nChest animation frames:")
    for frame, gid in ipairs(_game.map_manager.chest_anim) do
        print(string.format("Frame %d: Tile ID %d", frame - 1, gid))
    end
end

function debug.toggle()
    debug.enabled = not debug.enabled
end

-- Add debug to global game variable when loaded
_game = _game or {}
_game.debug = debug

return debug
