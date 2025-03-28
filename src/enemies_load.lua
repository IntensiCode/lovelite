local pos = require("src.base.pos")

-- Constants
local JUMP_SPEED = 5

local enemies_load = {}

---Load enemies from the dungeon map
---@param enemies table The enemies module table
---@param game table The game module table
function enemies_load.load(enemies, game)
    -- Clear existing enemies
    enemies.items = {}

    -- Get the Objects layer
    local objects_layer = game.dungeon.get_objects_layer()

    -- Process each tile in the Objects layer
    for y = 1, objects_layer.height do
        for x = 1, objects_layer.width do
            local tile = game.dungeon.get_objects_tile(x, y)
            if tile and tile.properties and tile.properties["kind"] == "enemy" then
                local enemy_data = game.dungeon.enemies[tile.gid]
                -- Clone the enemy data and add instance-specific properties
                local enemy = table.clone(enemy_data)
                -- Add instance-specific properties
                enemy.pos = pos.new(x + 0.5, y + 0.5)
                enemy.tile = tile
                enemy.name = tile.properties["name"] or "Enemy"
                enemy.is_dead = false
                enemy.will_retreat = enemy_data.will_retreat ~= false -- Default to true unless explicitly set to false
                -- Map weapon directly from weapons table
                enemy.weapon = DI.weapons[enemy_data.weapon] or nil
                -- Debug print error if weapon is not found
                if not enemy.weapon then
                    if enemy.behavior ~= "apprentice" then
                        log.error("WEAPON NOT FOUND")
                        log.error("Weapon name:", enemy_data.weapon)
                        log.error("Enemy name:", enemy.name)
                        table.print_deep("enemy", enemy)
                    end
                end
                -- Initialize jump properties with random initial delay
                enemy.jump_height = 0
                enemy.jump_time = 0
                enemy.next_jump_delay = math.random() * 0.5 -- Initial delay still random 0-0.5
                enemy.jump_speed = JUMP_SPEED
                -- Set unique ID based on behavior and index
                enemy.id = enemy.behavior .. "_" .. #enemies.items + 1
                table.insert(enemies.items, enemy)
            end
        end
    end

    -- Debug print enemies
    log.info("Enemies loaded:")
    for i, enemy in ipairs(enemies.items) do
        log.info(string.format("  %d. %s at (%d, %d) with %d HP, AC %d, and resistances (F:%s I:%s L:%s)",
            i, enemy.behavior or "Unknown", enemy.pos.x, enemy.pos.y, enemy.hitpoints or 0, enemy.armorclass or 0,
            enemy.resistance_fire or "N/A", enemy.resistance_ice or "N/A", enemy.resistance_lightning or "N/A"))
    end
end

return enemies_load 