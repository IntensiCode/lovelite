local fow_debug = {}

-- Flag to track if the debug grid should be shown
fow_debug.show_grid = false

---Debug draw function to visualize the fog grid
---@param fog_of_war table The main fog of war module
function fow_debug.draw_grid(fog_of_war)
    if not fow_debug.show_grid then return end
    
    -- Draw a small representation of the fog grid
    local scale = 2  -- Scale of the debug grid (in pixels per tile)
    local offsetX = 10
    local offsetY = 40
    
    -- Draw grid background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", offsetX - 2, offsetY - 2, 
        (fog_of_war.size.x * scale) + 4, 
        (fog_of_war.size.y * scale) + 4
    )
    
    -- Draw grid cells
    for y = 1, fog_of_war.size.y do
        for x = 1, fog_of_war.size.x do
            local value = fog_of_war.grid[y][x]
            if value == 0 then
                -- Unseen - black
                love.graphics.setColor(0, 0, 0, 1)
            elseif value == 1 then
                -- Edge - dark gray
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
            elseif value == 2 then
                -- Visible - light gray
                love.graphics.setColor(0.7, 0.7, 0.7, 1)
            end
            
            love.graphics.rectangle("fill", 
                offsetX + (x - 1) * scale, 
                offsetY + (y - 1) * scale,
                scale, scale
            )
        end
    end
    
    -- Highlight player position
    if DI.player and DI.player.pos then
        local px = math.floor(DI.player.pos.x)
        local py = math.floor(DI.player.pos.y)
        
        if fog_of_war.is_valid_position(px, py) then
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.rectangle("line", 
                offsetX + (px - 1) * scale, 
                offsetY + (py - 1) * scale,
                scale, scale
            )
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw fog status
    love.graphics.print("Fog: " .. (fog_of_war.enabled and "ON" or "OFF"), offsetX, offsetY - 20)
end

---Toggle the debug grid display
function fow_debug.toggle_grid()
    fow_debug.show_grid = not fow_debug.show_grid
    log.info("Fog debug grid: " .. (fow_debug.show_grid and "ON" or "OFF"))
end

---Register debug commands
---@param fog_of_war table The main fog of war module
function fow_debug.register_commands(fog_of_war)
    if not DI or not DI.debug then return end
    
    DI.debug.add_command("fog_reveal_all", function()
        fog_of_war.reveal_all()
        return "Revealed entire map"
    end, "Reveals the entire fog of war map")
    
    DI.debug.add_command("fog_toggle", function()
        local was_enabled = fog_of_war.enabled
        fog_of_war.set_enabled(not was_enabled)
        return "Fog of war " .. (fog_of_war.enabled and "enabled" or "disabled")
    end, "Toggles fog of war on/off")
    
    DI.debug.add_command("fog_status", function()
        local playerPos = ""
        if DI.player and DI.player.pos then
            playerPos = "Player pos: " .. math.floor(DI.player.pos.x) .. "," .. math.floor(DI.player.pos.y)
        end
        
        local visibility = ""
        if DI.player and DI.player.pos then
            local px = math.floor(DI.player.pos.x)
            local py = math.floor(DI.player.pos.y)
            if fog_of_war.is_valid_position(px, py) then
                visibility = "Visibility at player: " .. fog_of_war.grid[py][px]
            end
        end
        
        return "Fog enabled: " .. tostring(fog_of_war.enabled) .. 
               "\nInner radius: " .. fog_of_war.inner_radius .. 
               "\nOuter radius: " .. fog_of_war.outer_radius ..
               "\n" .. playerPos ..
               "\n" .. visibility
    end, "Shows fog of war status information")
    
    DI.debug.add_command("fog_grid", function()
        fow_debug.toggle_grid()
        return "Fog debug grid: " .. (fow_debug.show_grid and "ON" or "OFF")
    end, "Toggles the fog of war debug grid")
end

return fow_debug 