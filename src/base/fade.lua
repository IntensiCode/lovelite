local fade = {
    -- State
    alpha = 0,
    target = 0,
    timer = 0,
    duration = 0.2,
    transitioning = false,
    on_fade_done = nil  -- Callback when fade completes
}

---Reset the fade state
---@param direction "fade_in"|"fade_out" direction of fade transition
---@param duration? number optional fade duration in seconds (default: 0.2)
function fade.reset(direction, duration)
    if direction ~= "fade_in" and direction ~= "fade_out" then
        error("Invalid fade direction: " .. tostring(direction))
    end
    
    fade.alpha = direction == "fade_in" and 1.0 or 0.0
    fade.target = direction == "fade_in" and 0.0 or 1.0
    fade.timer = 0
    fade.duration = duration or 0.2
    fade.transitioning = true
end

---Update fade state
---@param dt number delta time in seconds
function fade.update(dt)
    if not fade.transitioning then
        return
    end

    if fade.alpha ~= fade.target then
        fade.timer = fade.timer + dt
        local progress = math.min(fade.timer / fade.duration, 1.0)
        local start_alpha = fade.alpha > fade.target and 1.0 or 0.0
        local end_alpha = fade.alpha > fade.target and 0.0 or 1.0
        fade.alpha = start_alpha + (end_alpha - start_alpha) * progress

        -- Check if fade is complete
        if progress >= 1.0 then
            fade.transitioning = false
            if fade.on_fade_done then
                fade.on_fade_done()
                fade.on_fade_done = nil  -- Clear callback after use
            end
        end
    end
end

---Draw the fade overlay
---@param width number screen width
---@param height number screen height
function fade.draw(width, height)
    if fade.alpha > 0 then
        love.graphics.setColor(0, 0, 0, fade.alpha)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return fade 