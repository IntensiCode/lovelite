---
-- Auto Quit module for quitting the game after a delay.
-- @module auto_quit

local auto_quit = {}

--- Create an auto-quit overlay that quits after a specified delay
--- @param delay number Time in seconds to wait before quitting
function auto_quit.create_overlay(delay)
    -- Create a timer and closure for the overlay
    local timer = tonumber(delay) or 1

    return {
        update = function(dt)
            timer = timer - dt
            if timer <= 0 then
                log.info("Auto-quitting now via auto_quit module overlay.")
                love.event.quit(0) -- Quit successfully
            end
        end
    }
end

--- Schedule the game to auto-quit after a specified delay using an overlay.
-- @param delay number Time in seconds to wait before quitting.
function auto_quit.schedule(delay)
    if not delay or delay <= 0 then
        log.error("Invalid delay specified for auto_quit.schedule: " .. tostring(delay))
        return
    end

    local overlay = auto_quit.create_overlay(delay)
    DI.screen.add_overlay(overlay)

    log.info("Auto-quit scheduled via overlay after " .. delay .. " seconds.")
end

return auto_quit
