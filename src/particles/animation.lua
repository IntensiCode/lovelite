local Vector2 = require("src.vector2")

---@class Animation
---@field frames table Array of frame data
---@field frame_duration number Time between frames in seconds
---@field pixel_size number Size of each pixel in the animation

---@class AnimatedParticle
---@field pos Vector2
---@field velocity Vector2
---@field color table
---@field size number
---@field life number
---@field max_life number
---@field kind string
---@field current_frame number
---@field frame_timer number
---@field animation Animation
---@field rotation number
---@field rotation_speed number

-- Animation data
local animations = {
    fire = {
        frames = {
            {
                {0,0,1,0,0},
                {0,1,1,1,0},
                {1,1,1,1,1},
                {0,1,1,1,0},
                {0,0,1,0,0}
            },
            {
                {0,1,0,1,0},
                {1,1,1,1,1},
                {0,1,1,1,0},
                {0,1,1,1,0},
                {0,0,1,0,0}
            },
            {
                {0,0,1,0,0},
                {0,1,1,1,0},
                {1,1,1,1,1},
                {0,1,1,1,0},
                {0,1,0,1,0}
            },
            {
                {0,1,0,1,0},
                {1,1,1,1,1},
                {0,1,1,1,0},
                {0,1,0,1,0},
                {0,0,1,0,0}
            }
        },
        frame_duration = 0.1,
        pixel_size = 2  -- Size of each pixel in the animation
    },
    ice = {
        frames = {
            {   -- Frame 1: Basic crystal
                {0,0,1,0,0},
                {0,1,1,1,0},
                {1,1,0,1,1},
                {0,1,1,1,0},
                {0,0,1,0,0}
            },
            {   -- Frame 2: Sparkle top-right
                {0,0,1,1,0},
                {0,1,1,1,0},
                {1,1,0,1,1},
                {0,1,1,1,0},
                {0,0,1,0,0}
            },
            {   -- Frame 3: Sparkle bottom-left
                {0,0,1,0,0},
                {0,1,1,1,0},
                {1,1,0,1,1},
                {1,1,1,1,0},
                {0,0,1,0,0}
            },
            {   -- Frame 4: Crystal slightly rotated
                {0,1,1,0,0},
                {0,1,1,1,0},
                {1,1,0,1,1},
                {0,1,1,1,0},
                {0,0,1,1,0}
            }
        },
        frame_duration = 0.15,  -- Slightly slower than fire
        pixel_size = 2
    }
}

local AnimatedParticle = {}
AnimatedParticle.__index = AnimatedParticle

---Create a new animated particle
---@param pos Vector2 Initial position
---@param velocity Vector2 Initial velocity
---@param life number Lifetime in seconds
---@param kind string Type of particle ("fire" or "ice")
---@return AnimatedParticle
function AnimatedParticle.new(pos, velocity, life, kind)
    local particle = {
        pos = pos,
        velocity = velocity,
        color = {1, 1, 1, 1},
        life = life,
        max_life = life,
        kind = kind,
        current_frame = 1,
        frame_timer = 0,
        rotation = kind == "ice" and math.random() * math.pi * 2 or 0,
        rotation_speed = kind == "ice" and (math.random() - 0.5) * 2 or 0
    }
    setmetatable(particle, AnimatedParticle)
    return particle
end

---Update the animated particle
---@param dt number Delta time in seconds
function AnimatedParticle:update(dt)
    -- Update position
    self.pos = self.pos + self.velocity * dt
    
    -- Update life
    self.life = self.life - dt
    
    -- Update animation
    self.frame_timer = self.frame_timer + dt
    local anim = animations[self.kind]
    if self.frame_timer >= anim.frame_duration then
        self.frame_timer = self.frame_timer - anim.frame_duration
        self.current_frame = self.current_frame + 1
        if self.current_frame > #anim.frames then
            self.current_frame = 1
        end
    end
    
    -- Update rotation
    if self.rotation_speed ~= 0 then
        self.rotation = self.rotation + self.rotation_speed * dt
    end
end

---Draw the animated particle
function AnimatedParticle:draw()
    local anim = animations[self.kind]
    local frame = anim.frames[self.current_frame]
    local pixel_size = anim.pixel_size
    
    -- Save current transform
    love.graphics.push()
    
    -- Move to particle center and apply rotation
    love.graphics.translate(self.pos.x, self.pos.y)
    if self.rotation ~= 0 then
        love.graphics.rotate(self.rotation)
    end
    
    -- Draw each pixel of the frame
    for y = 1, #frame do
        for x = 1, #frame[y] do
            if frame[y][x] == 1 then
                if self.kind == "fire" then
                    -- Fire gradient: red to yellow
                    local yellow = math.max(0, 1 - (y / #frame))
                    love.graphics.setColor(1, yellow, 0, self.color[4])
                elseif self.kind == "ice" then
                    -- Ice gradient: white-blue-white cycle
                    local progress = (self.life / self.max_life + self.frame_timer / anim.frame_duration) * 2
                    local blue_intensity = math.abs(math.sin(progress * math.pi))
                    -- Blend between white (1,1,1) and light blue (0.7,0.8,1)
                    love.graphics.setColor(
                        0.7 + (1 - blue_intensity) * 0.3,  -- red
                        0.8 + (1 - blue_intensity) * 0.2,  -- green
                        1,                                  -- blue
                        self.color[4]                      -- alpha
                    )
                end
                
                love.graphics.rectangle(
                    "fill",
                    (x-1) * pixel_size - (#frame[y] * pixel_size)/2,
                    (y-1) * pixel_size - (#frame * pixel_size)/2,
                    pixel_size,
                    pixel_size
                )
            end
        end
    end
    
    -- Restore transform
    love.graphics.pop()
end

---Get the color for an ice particle based on its lifetime
---@param t number Normalized lifetime (0 to 1)
---@return table color RGBA color array
local function get_ice_color(t)
    if t > 0.6 then
        -- Dark blue to blue (0,0,0.8) -> (0,0.3,1)
        local blend = (t - 0.6) / 0.4
        return {
            0,                   -- stays 0
            0.3 * blend,        -- 0 -> 0.3
            0.8 + 0.2 * blend,  -- 0.8 -> 1
            1
        }
    elseif t > 0.2 then
        -- Blue to turkish blue (0,0.3,1) -> (0,0.6,1)
        local blend = (t - 0.2) / 0.4
        return {
            0,                   -- stays 0
            0.3 + 0.3 * blend,  -- 0.3 -> 0.6
            1,                   -- stays 1
            1
        }
    else
        -- Fade out turkish blue
        return {0, 0.6, 1, t * 5}
    end
end

---Get the color for a fire particle based on its lifetime
---@param t number Normalized lifetime (0 to 1)
---@return table color RGBA color array
local function get_fire_color(t)
    if t > 0.6 then
        -- White to yellow (1,1,1) -> (1,1,0)
        local yellow = (t - 0.6) / 0.4  -- 0 to 1
        return {1, 1, yellow, 1}
    elseif t > 0.2 then
        -- Yellow to red (1,1,0) -> (1,0,0)
        local red = (t - 0.2) / 0.4  -- 0 to 1
        return {1, red, 0, 1}
    else
        -- Red to transparent (1,0,0) -> (1,0,0,0)
        return {1, 0, 0, t * 5}  -- Fade out in last 20%
    end
end

return {
    new = AnimatedParticle.new,
    get_ice_color = get_ice_color,
    get_fire_color = get_fire_color
} 