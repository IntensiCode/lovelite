--- Screenshot module for taking timed screenshots
--- @module screenshot

local screenshot = {}

--- Save a screenshot to the screenshots directory
--- @param imageData love.ImageData The image data to save
--- @param filename string The filename to save as
--- @return boolean success Whether the save was successful
--- @return string? error Error message if save failed
local function save_screenshot(imageData, filename)
    local success, err = pcall(function()
        love.filesystem.createDirectory("screenshots")
        local fileData = imageData:encode("png")
        love.filesystem.write("screenshots/" .. filename, fileData)
    end)
    
    if success then
        local savePath = love.filesystem.getSaveDirectory() .. "/screenshots/" .. filename
        log.info("Screenshot saved to: " .. savePath)
    else
        log.error("Failed to save screenshot: " .. tostring(err))
    end
    
    return success
end

--- Capture screenshot and process it
--- @param filename string The filename to save as
local function capture_and_save(filename)
    love.graphics.captureScreenshot(function(imageData)
        save_screenshot(imageData, filename)
        love.event.quit(0)
    end)
end

--- Create a screenshot overlay that takes a screenshot after a specified delay
--- @param delay number Time in seconds to wait before taking the screenshot
--- @param filename string Name of the file to save the screenshot to
function screenshot.create_overlay(delay, filename)
    filename = filename or "screenshot.png"
    
    -- Create a timer and closure for the overlay
    local timer = tonumber(delay) or 1
    
    return {
        update = function(dt)
            timer = timer - dt
            if timer <= 0 then
                capture_and_save(filename)
            end
        end
    }
end

--- Take a screenshot after a delay and exit the application
--- @param delay number Time in seconds to wait before taking the screenshot
--- @param filename string? Name of the file to save the screenshot to (default: screenshot.png)
function screenshot.schedule(delay, filename)
    local overlay = screenshot.create_overlay(delay, filename)
    DI.screen.add_overlay(overlay)
end

return screenshot 