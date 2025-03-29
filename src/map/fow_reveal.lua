local pos = require("src.base.pos")

local fow_reveal = {}

---Check if a tile position is valid in the grid
---@param fog_of_war table The main fog of war module
---@param x number Tile X coordinate
---@param y number Tile Y coordinate
---@return boolean is_valid Whether the position is within the grid
function fow_reveal.is_valid_position(fog_of_war, x, y)
    return x >= 1 and x <= fog_of_war.size.x and 
           y >= 1 and y <= fog_of_war.size.y
end

---Reveal tiles around a position within the visibility radius
---@param fog_of_war table The main fog of war module
---@param center_pos pos Position to reveal around (in tiles, centered)
---@return boolean Changed whether any tiles were newly revealed
function fow_reveal.reveal_around(fog_of_war, center_pos)
    if not fog_of_war.enabled then return false end
    
    -- Convert from center position to tile position
    local tile_x = math.floor(center_pos.x)
    local tile_y = math.floor(center_pos.y)
    
    -- Check if player has moved to a new tile, if not, no need to update
    if fog_of_war.prev_player_pos and 
       math.floor(fog_of_war.prev_player_pos.x) == tile_x and 
       math.floor(fog_of_war.prev_player_pos.y) == tile_y then
        return false
    end
    
    -- Update previous position
    fog_of_war.prev_player_pos = pos.new(center_pos.x, center_pos.y)
    
    -- Track if any tile was newly revealed
    local changed = false
    
    -- Update visibility for each tile in the maximum radius
    local max_radius = fog_of_war.outer_radius
    for y = tile_y - max_radius, tile_y + max_radius do
        for x = tile_x - max_radius, tile_x + max_radius do
            if fow_reveal.is_valid_position(fog_of_war, x, y) then
                -- Calculate distance from center
                local dx = x - center_pos.x
                local dy = y - center_pos.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                -- Set visibility level based on distance
                local old_value = fog_of_war.grid[y][x]
                local new_value = 0
                
                if distance <= fog_of_war.inner_radius then
                    -- Fully visible zone
                    new_value = 2
                elseif distance <= fog_of_war.outer_radius then
                    -- Transition zone
                    new_value = 1
                end
                
                -- Only increase visibility, never decrease it
                if new_value > old_value then
                    changed = true
                    fog_of_war.grid[y][x] = new_value
                end
            end
        end
    end
    
    return changed
end

---Reveal the entire map
---@param fog_of_war table The main fog of war module
function fow_reveal.reveal_all(fog_of_war)
    local changed = false
    
    for y = 1, fog_of_war.size.y do
        for x = 1, fog_of_war.size.x do
            if fog_of_war.grid[y][x] ~= 2 then  -- Check if already fully visible
                fog_of_war.grid[y][x] = 2  -- Fully visible
                changed = true
            end
        end
    end
    
    return changed
end

return fow_reveal 