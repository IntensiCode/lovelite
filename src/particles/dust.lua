local Vector2 = require("src.vector2")

---@class DustParticle
---@field pos Vector2
---@field velocity Vector2
---@field color table
---@field size number
---@field life number
---@field max_life number
---@field kind string
local DustParticle = {}
DustParticle.__index = DustParticle

---Create a new dust particle
---@param pos Vector2 Initial position
---@param velocity Vector2 Initial velocity
---@param life number Lifetime in seconds
---@param size number Size of the dust particle
---@return DustParticle
function DustParticle.new(pos, velocity, life, size)
    local particle = {
        pos = pos,
        velocity = velocity,
        color = {1, 1, 1, 1},  -- Start white
        size = size,
        life = life,
        max_life = life,
        kind = "dust"
    }
    setmetatable(particle, DustParticle)
    return particle
end

---Update the dust particle
---@param dt number Delta time in seconds
function DustParticle:update(dt)
    -- Update position
    self.pos = self.pos + self.velocity * dt
    
    -- Update life
    self.life = self.life - dt
    
    -- Update color (fade from white to gray while becoming transparent)
    local t = self.life / self.max_life
    local gray = 0.5 + 0.5 * t  -- Fade from 1 to 0.5
    self.color = {gray, gray, gray, t}
end

---Draw the dust particle
function DustParticle:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", self.pos.x, self.pos.y, self.size)
end

---Spawn dust particles at a position
---@param pos Vector2 The position to spawn particles at (in tile space)
---@param direction Vector2 The direction the particles should move in
---@return DustParticle[] Array of created dust particles
function DustParticle.spawn(pos, direction)
    -- Convert tile space position to screen space
    local screen_pos = Vector2.new(
        (pos.x - 1) * _game.map_manager.map.tilewidth,
        (pos.y - 1) * _game.map_manager.map.tileheight
    )
    
    -- Create multiple particles in a small area
    local count = direction and 4 or 12
    local particles = {}
    for i = 1, count do 
        -- Add some randomness to position
        local offset = Vector2.new(
            (math.random() - 0.5) * 4,  -- ±2 pixels
            (math.random() - 0.5) * 4
        )
        
        -- Calculate velocity based on direction
        local velocity = DustParticle.calculate_velocity(direction)

        -- Create dust particle
        local particle = DustParticle.new(
            screen_pos + offset,
            velocity * 60,  -- Scale up for dt multiplication
            0.5 * (0.8 + math.random() * 0.4),  -- Life with variation
            2  -- Size
        )
        
        table.insert(particles, particle)
    end
    
    return particles
end

---Calculate velocity for a dust particle
---@param direction Vector2|nil The direction the particle should move in, or nil for random direction
---@return Vector2 The calculated velocity vector
function DustParticle.calculate_velocity(direction)
    if direction then
        -- Use direction as base velocity with random spread
        local spread = math.pi / 4  -- 45 degree spread
        local angle = math.atan2(direction.y, direction.x)
        local particle_angle = angle + (math.random() - 0.5) * spread
        local speed = direction:length() * (0.5 + math.random() * 0.5)  -- 50-100% of base speed
        return Vector2.new(
            math.cos(particle_angle) * speed,
            math.sin(particle_angle) * speed
        )
    else
        -- Random direction for circular dust cloud
        local angle = math.random() * math.pi * 2  -- Random angle between 0 and 2π
        local speed = (0.1 + math.random() * 0.4)  -- Random speed between 1 and 2
        return Vector2.new(
            math.cos(angle) * speed,
            math.sin(angle) * speed
        )
    end
end

return DustParticle 