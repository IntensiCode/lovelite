local lg = love.graphics

local debug = {
    enabled = true
}

-- Helper function to dump a collection of tiles
local function dump_tiles(kind, which)
    log.debug(kind .. ":")
    for gid, data in pairs(which) do
        log.debug(string.format("Tile ID %d:", gid))
        table.print_deep("Data", data, "  ")
    end
end

---Draw red dots above all entity positions
function debug.draw_entity_positions()
    -- Set debug font if available
    local default_font = lg.getFont()
    lg.setFont(DI.font.tiny)

    local tile_size = DI.dungeon.tile_size

    -- Draw debug dots for all projectiles
    lg.setColor(1, 0, 0, 1) -- Red dot
    for _, it in ipairs(DI.projectiles.active) do
        local p = DI.dungeon.grid_to_screen(it.pos)
        lg.circle("fill", p.x, p.y, 3)
    end

    -- Draw enemy position dots in red first
    lg.setColor(1, 0, 0, 0.5) -- Red with 25% opacity
    for _, it in ipairs(DI.enemies.items) do
        local p = DI.dungeon.grid_to_screen(it.pos)
        lg.circle("fill", p.x, p.y, 3)
    end

    -- Draw player position dot in dark blue
    lg.setColor(0, 0, 0.8, 0.5) -- Dark blue with 25% opacity
    local p = DI.dungeon.grid_to_screen(DI.player.pos)
    lg.circle("fill", p.x, p.y, 3)

    -- Draw player position text with background
    local pos_text = string.format("%.2f, %.2f", DI.player.pos.x, DI.player.pos.y)
    local text_width = DI.font.tiny:getWidth(pos_text)
    local line_height = 9 -- 8px font height + 1px spacing
    local padding = 1

    -- Draw background for player position text (below player)
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill",
        p.x - text_width / 2 - padding,
        p.y + tile_size / 2 + padding, -- Position below player sprite
        text_width + padding * 2,
        line_height + padding * 2
    )

    -- Draw player position text
    lg.setColor(1, 1, 1, 1)
    lg.print(pos_text,
        p.x - text_width / 2,
        p.y + tile_size / 2 + padding * 2 -- Position below player sprite
    )

    -- Restore default font
    lg.setFont(default_font)
end

function debug.draw()
    if not debug.enabled then return end

    -- Store current graphics state
    lg.push()
    lg.origin() -- Reset transformations

    -- Set debug font if available
    local default_font = lg.getFont()
    lg.setFont(DI.font.tiny)

    -- Calculate text dimensions for background
    local info = {
        string.format("Player: %.1f, %.1f", DI.player.pos.x, DI.player.pos.y),
        string.format("Camera: %.1f, %.1f", DI.camera.world_pos.x, DI.camera.world_pos.y),
        string.format("Scale: %.2f", DI.camera.scale),
        string.format("FPS: %d", love.timer.getFPS())
    }

    local line_height = 9 -- 8px font height + 1px spacing
    local padding = 1
    local max_width = 0
    for _, text in ipairs(info) do
        max_width = math.max(max_width, DI.font.tiny:getWidth(text))
    end

    -- Draw semi-transparent black background
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill",
        0, -- Snap to left edge
        0, -- Snap to top edge
        max_width + padding * 2,
        #info * line_height + padding * 2
    )

    -- Draw debug text in white
    lg.setColor(1, 1, 1, 1)
    for i, text in ipairs(info) do
        lg.print(text, padding, padding + (i - 1) * line_height)
    end

    -- Draw fog of war debug visualization if available
    if DI.fog_of_war and DI.fog_of_war.debug_draw then
        DI.fog_of_war.debug_draw()
    end

    -- Restore default font
    lg.setFont(default_font)

    -- Restore previous graphics state
    lg.pop()
end

function debug.print_map_tiles()
    log.debug("Processed tiles:")

    dump_tiles("Enemies", DI.dungeon.enemies)
    dump_tiles("Weapons", DI.dungeon.weapons)
    dump_tiles("Shields", DI.dungeon.shields)

    log.debug("Chest animation frames:")
    for frame, gid in ipairs(DI.dungeon.chest_anim) do
        log.debug(string.format("Frame %d: Tile ID %d", frame - 1, gid))
    end
end

function debug.toggle()
    debug.enabled = not debug.enabled

    -- Also update log level when debug is toggled
    if debug.enabled then
        log.set_level(log.LEVELS.DEBUG)
    else
        log.set_level(log.LEVELS.INFO)
    end
end

-- Add a command to the registry
---@param name string Command name
---@param handler function Command handler function
---@param help string Optional help text
function debug.add_command(name, handler, help)
    DI.debug_commands.add_command(name, handler, help)
end

return debug
