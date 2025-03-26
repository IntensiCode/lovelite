local Vector2 = require("src.vector2")
local constants = require("src.particles.constants")

---@class LightningParticle
---@field pos Vector2
---@field velocity Vector2
---@field color table
---@field size number
---@field life number
---@field max_life number
---@field kind string
---@field jitter1 Vector2 Random offset for first zag point
---@field jitter2 Vector2 Random offset for middle point
---@field jitter3 Vector2 Random offset for second zag point
---@field jitter_time number Time counter for jitter movement
---@field delay number Delay before particle becomes visible
---@field flip_x boolean Whether to flip the x-axis pattern
---@field blink boolean Whether to skip drawing this frame
local LightningParticle = {}
LightningParticle.__index = LightningParticle

---Create a new lightning particle
---@param pos Vector2 Initial position
---@param velocity Vector2 Initial velocity
---@param life number Lifetime in seconds
---@param size number Size of the lightning
---@param delay number Initial delay before becoming visible
---@return LightningParticle
function LightningParticle.new(pos, velocity, life, size, delay)
    local particle = {
        pos = pos,
        velocity = velocity,
        color = {1, 1, 1, 1},
        size = size,
        life = life,
        max_life = life,
        kind = "lightning",
        jitter_time = math.random() * math.pi * 2,
        jitter1 = Vector2.new(0, 0),
        jitter2 = Vector2.new(0, 0),
        jitter3 = Vector2.new(0, 0),
        delay = delay,
        flip_x = math.random() < 0.5,
        blink = false
    }
    setmetatable(particle, LightningParticle)
    return particle
end

---Update the lightning particle
---@param dt number Delta time in seconds
function LightningParticle:update(dt)
    -- Update delay
    if self.delay > 0 then
        self.delay = self.delay - dt
        return
    end
    
    -- Update position
    self.pos = self.pos + self.velocity * dt
    
    -- Update life
    self.life = self.life - dt
    
    -- Update jitter
    self.jitter_time = self.jitter_time + dt * 10  -- Speed of jitter movement
    local jitter_amount = self.size * 0.5  -- Scale jitter with particle size
    
    -- Update each jitter point with smooth random movement
    self.jitter1 = Vector2.new(
        math.sin(self.jitter_time * 0.7) * jitter_amount,
        math.cos(self.jitter_time * 0.3) * jitter_amount
    )
    self.jitter2 = Vector2.new(
        math.sin(self.jitter_time * 0.1) * jitter_amount,
        math.cos(self.jitter_time * 0.9) * jitter_amount
    )
    self.jitter3 = Vector2.new(
        math.sin(self.jitter_time * 0.5) * jitter_amount,
        math.cos(self.jitter_time * 0.5) * jitter_amount
    )

    -- Update color based on lifetime
    local t = self.life / self.max_life
    self.color = LightningParticle.get_color(t)

    -- Randomly blink (10% chance)
    self.blink = math.random() < 0.1
end

---Draw a stylized lightning strike
---@param x number Center x position
---@param y number Center y position
---@param size number Base size of the lightning
---@param jitter1 Vector2 Offset for first zag point
---@param jitter2 Vector2 Offset for middle point
---@param jitter3 Vector2 Offset for second zag point
---@param scale_y number Vertical scale factor (0 to 1)
---@param flip_x boolean Whether to flip the x-axis pattern
local function draw_lightning_strike(x, y, size, jitter1, jitter2, jitter3, scale_y, flip_x)
    -- Draw a vertical zigzag pattern with jittered points
    -- Scale the zigzag width progressively larger towards the bottom
    -- Apply vertical scaling to make it grow
    love.graphics.setLineWidth(1)
    local x_mult = flip_x and -1 or 1  -- Multiplier for x coordinates
    love.graphics.line(
        x, y,     -- Start point (at center)
        x + x_mult * (-size/6) + jitter1.x, y + (-size/4 + jitter1.y) * scale_y,  -- First zag (small)
        x + jitter2.x, y + jitter2.y * scale_y,         -- Middle point
        x + x_mult * (size/3) + jitter3.x, y + (size/2 + jitter3.y) * scale_y,   -- Second zag (larger)
        x, y + size * scale_y       -- End point (scaled by growth)
    )
end

---Draw the lightning particle
function LightningParticle:draw()
    if self.delay > 0 or self.blink then
        return
    end

    -- Calculate growth based on lifetime
    local growth = math.min(1, (1 - self.life / self.max_life) * 4)
    draw_lightning_strike(
        self.pos.x, 
        self.pos.y, 
        self.size * 3,
        self.jitter1,
        self.jitter2,
        self.jitter3,
        growth,
        self.flip_x
    )
end

---Get the color for a lightning particle based on its lifetime
---@param t number Normalized lifetime (0 to 1)
---@return table color RGBA color array
function LightningParticle.get_color(t)
    if t > 0.75 then
        -- White (1,1,1)
        return {1, 1, 1, 1}
    elseif t > 0.5 then
        -- Yellow (1,1,0)
        return {1, 1, 0, 1}
    elseif t > 0.25 then
        -- White again (1,1,1)
        return {1, 1, 1, 1}
    else
        -- Black to transparent (0,0,0) -> (0,0,0,0)
        return {0, 0, 0, t * 4}
    end
end

---@param pos Vector2 The position to spawn particles at (in tile space)
---@return table Array of lightning particles
function LightningParticle.spawn(pos)
    -- Convert tile space position to screen space
    local screen_pos = Vector2.new(
        (pos.x - 1) * _game.map_manager.map.tilewidth,
        (pos.y - 1) * _game.map_manager.map.tileheight
    )
    
    local particles = {}
    for i = 1, constants.magic_count do
        -- Add some randomness to position
        local offset = Vector2.new(
            (math.random() - 0.5) * 4,  -- ±2 pixels
            (math.random() - 0.5) * 4
        )
        
        -- Lightning moves horizontally with slight random direction
        local direction = math.random() < 0.5 and -1 or 1  -- Random left or right
        local velocity = Vector2.new(
            direction * constants.lightning_drift_speed * (0.8 + math.random() * 0.4),
            0  -- No vertical movement
        )
        
        local particle = LightningParticle.new(
            screen_pos + offset,
            velocity * 60,
            constants.magic_life * (0.8 + math.random() * 0.4),
            constants.magic_size * (0.8 + math.random() * 0.4),
            math.random() * constants.lightning_delay_max
        )
        
        table.insert(particles, particle)
    end
    
    return particles
end

return LightningParticle 