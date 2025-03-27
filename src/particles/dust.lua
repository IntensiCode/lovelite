local pos = require("src.base.pos")

---@class DustParticle
---@field pos pos
---@field velocity pos
---@field color table
---@field size number
---@field life number
---@field max_life number
---@field kind string
local DustParticle = {}
DustParticle.__index = DustParticle

---Create a new dust particle
---@param pos pos Initial position
---@param velocity pos Initial velocity
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

---Spawn a single dust particle at a position
---@param pos pos The position to spawn particle at (in screen space)
---@param direction? pos The direction the particle should move in
---@return DustParticle The created dust particle
function DustParticle.spawn(pos, direction)
    -- Add some randomness to position
    local offset = pos.new(
        (math.random() - 0.5) * 4,  -- ±2 pixels
        (math.random() - 0.5) * 4
    )
    
    -- Calculate velocity based on direction
    local velocity = DustParticle.calculate_velocity(direction)

    -- Create dust particle
    return DustParticle.new(
        pos + offset,
        velocity * 60,  -- Scale up for dt multiplication
        0.5 * (0.8 + math.random() * 0.4),  -- Life with variation
        2  -- Size
    )
end

---Calculate velocity for a dust particle
---@param direction pos|nil The direction the particle should move in, or nil for random direction
---@return pos The calculated velocity vector
function DustParticle.calculate_velocity(direction)
    if direction then
        -- Use direction as base velocity with random spread
        local spread = math.pi / 4  -- 45 degree spread
        local angle = math.atan2(direction.y, direction.x)
        local particle_angle = angle + (math.random() - 0.5) * spread
        local speed = direction:length() * (0.5 + math.random() * 0.5)  -- 50-100% of base speed
        return pos.new(
            math.cos(particle_angle) * speed,
            math.sin(particle_angle) * speed
        )
    else
        -- Random direction for circular dust cloud
        local angle = math.random() * math.pi * 2  -- Random angle between 0 and 2π
        local speed = (0.1 + math.random() * 0.4)  -- Random speed between 1 and 2
        return pos.new(
            math.cos(angle) * speed,
            math.sin(angle) * speed
        )
    end
end

return DustParticle 