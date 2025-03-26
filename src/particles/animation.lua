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
---@field color_hook function Function to update particle color based on lifetime
---@field anim Animation The animation data for this particle

local AnimatedParticle = {}
AnimatedParticle.__index = AnimatedParticle

---Create a new animated particle
---@param pos Vector2 Initial position
---@param velocity Vector2 Initial velocity
---@param life number Lifetime in seconds
---@param kind string Type of particle ("fire" or "ice")
---@param color_hook function Function to update particle color based on lifetime
---@param anim Animation The animation data for this particle
---@return AnimatedParticle
function AnimatedParticle.new(pos, velocity, life, kind, color_hook, anim)
    local particle = {
        pos = pos,
        velocity = velocity,
        color = { 1, 1, 1, 1 },
        life = life,
        max_life = life,
        kind = kind,
        current_frame = 1,
        frame_timer = 0,
        rotation = kind == "ice" and math.random() * math.pi * 2 or 0,
        rotation_speed = kind == "ice" and (math.random() - 0.5) * 2 or 0,
        color_hook = color_hook,
        anim = anim
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
    local anim = self.anim
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

    -- Update color using the hook
    local t = self.life / self.max_life
    self.color = self.color_hook(t)
end

---Draw the animated particle
function AnimatedParticle:draw()
    local anim = self.anim
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
                    -- Ice gradient: checkerboard pattern between turkish blue and whitish blue
                    local progress = (self.life / self.max_life + self.frame_timer / anim.frame_duration) * 2
                    local blue_intensity = math.abs(math.sin(progress * math.pi))
                    
                    -- Get screen position for checkerboard pattern
                    local screen_x = math.floor(self.pos.x)
                    local screen_y = math.floor(self.pos.y)
                    local is_checker = (screen_x + screen_y) % 2 == 0
                    
                    if is_checker then
                        -- Turkish blue (0.2, 0.6, 0.8)
                        love.graphics.setColor(
                            0.2 + (1 - blue_intensity) * 0.1,  -- red
                            0.6 + (1 - blue_intensity) * 0.2,  -- green
                            0.8 + (1 - blue_intensity) * 0.2,  -- blue
                            1                                   -- alpha
                        )
                    else
                        -- Whitish blue (0.7, 0.8, 1)
                        love.graphics.setColor(
                            0.7 + (1 - blue_intensity) * 0.3,  -- red
                            0.8 + (1 - blue_intensity) * 0.2,  -- green
                            1,                                 -- blue
                            1                                  -- alpha
                        )
                    end
                end

                love.graphics.rectangle(
                    "fill",
                    (x - 1) * pixel_size - (#frame[y] * pixel_size) / 2,
                    (y - 1) * pixel_size - (#frame * pixel_size) / 2,
                    pixel_size,
                    pixel_size
                )
            end
        end
    end

    -- Restore transform
    love.graphics.pop()
end

return {
    new = AnimatedParticle.new
}
