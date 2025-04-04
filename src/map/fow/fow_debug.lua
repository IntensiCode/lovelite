-- FOW Debug Module
-- Provides debugging tools and visualizations for the fog of war system.
-- Displays a miniature grid view of the fog visibility levels.
-- Registers console commands for toggling and manipulating fog settings.
-- Includes a legend to help interpret visibility levels during development.

local camera = require("src.base.camera")
local fow_config = require("src.map.fow.fow_config")
local fow_memory = require("src.map.fow.fow_memory")
local levels = require("src.map.fow.fow_levels")
local fow_debug = {}

-- Flag to track if the debug grid should be shown
fow_debug.show_grid = false

local scale = 1 -- Scale of the debug grid (in pixels per tile)

local colors = {
    [levels.HIDDEN_0] = { 0, 0, 0, 0.75 },
    [levels.HEAVY_FOG_1] = { 0.15, 0.15, 0.15, 0.75 },
    [levels.MEDIUM_FOG_2] = { 0.3, 0.3, 0.3, 0.75 },
    [levels.LIGHT_FOG_3] = { 0.5, 0.5, 0.5, 0.75 },
    [levels.VISIBLE_4] = { 0.7, 0.7, 0.7, 0.75 },
}

local function highlight_player(offset_x, offset_y)
    local px = math.floor(DI.player.pos.x)
    local py = math.floor(DI.player.pos.y)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle(
        "line",
        offset_x + (px - 1) * scale,
        offset_y + (py - 1) * scale,
        scale,
        scale
    )
end

local function draw_grid_background(offset_x, offset_y)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle(
        "fill",
        offset_x - 2,
        offset_y - 2,
        (fow_config.size.x * scale) + 4,
        (fow_config.size.y * scale) + 4
    )
end

local function draw_grid_cells(offset_x, offset_y)
    for y = 1, fow_config.size.y do
        for x = 1, fow_config.size.x do
            local fog_level = fow_memory.grid[y][x]
            love.graphics.setColor(colors[fog_level])
            love.graphics.rectangle(
                "fill",
                offset_x + (x - 1) * scale,
                offset_y + (y - 1) * scale,
                scale,
                scale
            )
        end
    end

    highlight_player(offset_x, offset_y)
end

local function draw_fog_status(offset_x, offset_y)
    local text = "Fog: " .. (fow_config.enabled and "ON" or "OFF")
    DI.font.draw_text(text, offset_x, offset_y)
end

function fow_debug.draw_grid()
    if not fow_debug.show_grid then
        return
    end

    local offset_x = camera.width - fow_config.size.x * scale - 2
    local offset_y = camera.height - fow_config.size.y * scale - 2
    love.graphics.setColor(1, 1, 1, 1)
    draw_fog_status(offset_x, offset_y - 10)
    draw_grid_background(offset_x, offset_y)
    draw_grid_cells(offset_x, offset_y)
end

---Toggle the debug grid display
function fow_debug.toggle_grid()
    fow_debug.show_grid = not fow_debug.show_grid
    log.debug("Fog debug grid: " .. (fow_debug.show_grid and "ON" or "OFF"))
end

---Register debug commands
---@param fog_of_war table The main fog of war module
function fow_debug.register_commands(fog_of_war)
    DI.debug.add_command("fog_reveal_all", function()
        fog_of_war.reveal_all()
        return "Revealed entire map"
    end, "Reveals the entire fog of war map")

    DI.debug.add_command("fog_toggle", function()
        local was_enabled = fow_config.enabled
        fog_of_war.set_enabled(not was_enabled)
        return "Fog of war " .. (fow_config.enabled and "enabled" or "disabled")
    end, "Toggles fog of war on/off")

    DI.debug.add_command("fog_status", function()
        local playerPos = ""
        if DI.player and DI.player.pos then
            playerPos = "Player pos: "
                .. math.floor(DI.player.pos.x)
                .. ","
                .. math.floor(DI.player.pos.y)
        end

        local visibility = ""
        if DI.player and DI.player.pos then
            local px = math.floor(DI.player.pos.x)
            local py = math.floor(DI.player.pos.y)
            if fog_of_war.is_valid_position(px, py) then
                local level = fow_memory.grid[py][px]
                local level_name = "Unknown"
                if level == 0 then
                    level_name = "Unseen"
                elseif level == 1 then
                    level_name = "Heavy Fog"
                elseif level == 2 then
                    level_name = "Medium Fog"
                elseif level == 3 then
                    level_name = "Light Fog"
                elseif level == 4 then
                    level_name = "Visible"
                end
                visibility = "Visibility at player: "
                    .. level
                    .. " ("
                    .. level_name
                    .. ")"
            end
        end

        return "Fog enabled: "
            .. tostring(fow_config.enabled)
            .. "\nField of view mode: "
            .. tostring(fow_config.field_of_view_mode)
            .. "\nInner radius: "
            .. fow_config.inner_radius
            .. "\nOuter radius: "
            .. fow_config.outer_radius
            .. "\n"
            .. playerPos
            .. "\n"
            .. visibility
    end, "Shows fog of war status information")

    DI.debug.add_command("fog_grid", function()
        fow_debug.toggle_grid()
        return "Fog debug grid: " .. (fow_debug.show_grid and "ON" or "OFF")
    end, "Toggles the fog of war debug grid")

    DI.debug.add_command("fog_field_of_view", function()
        fog_of_war.toggle_field_of_view_mode()
        return "Field of view mode: "
            .. (fog_of_war.field_of_view_mode and "ON" or "OFF")
    end, "Toggles between field of view mode and traditional fog of war")
end

return fow_debug
