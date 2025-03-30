--- Tests for the screen overlay system
--- @module test_screen

local lu = require("src.libraries.luaunit")
local screen_module = "src.base.screen"
local screen = require(screen_module)

--- Test suite for screen overlay system
TestScreenOverlay = {}

function TestScreenOverlay:setUp()
    -- Reload the screen module for each test to ensure clean state
    package.loaded[screen_module] = nil
    screen = require(screen_module)
    
    -- Reset the overlay list before each test (as a backup)
    screen.overlays = {}
end

function TestScreenOverlay:tearDown()
    -- Clean up after each test
    screen.overlays = {}
end

function TestScreenOverlay:test_add_overlay()
    local test_overlay = { test_flag = true }
    screen.add_overlay(test_overlay)
    
    lu.assertEquals(#screen.overlays, 1, "Should add overlay to the list")
    lu.assertIs(screen.overlays[1], test_overlay, "Should store the exact overlay object")
end

function TestScreenOverlay:test_remove_overlay()
    local test_overlay1 = { id = 1 }
    local test_overlay2 = { id = 2 }
    
    screen.add_overlay(test_overlay1)
    screen.add_overlay(test_overlay2)
    lu.assertEquals(#screen.overlays, 2, "Should have two overlays")
    
    screen.remove_overlay(test_overlay1)
    lu.assertEquals(#screen.overlays, 1, "Should have one overlay after removal")
    lu.assertEquals(screen.overlays[1].id, 2, "Should keep the correct overlay")
end

function TestScreenOverlay:test_overlay_update_method_called()
    -- Create test overlay with update method
    local update_called = false
    local test_overlay = {
        update = function(dt) update_called = true end
    }
    
    screen.add_overlay(test_overlay)
    
    -- Mock the current screen to prevent errors
    screen.screens["test"] = { update = function() end, draw = function() end, resize = function() end }
    screen.current = "test"
    
    -- Call the love.update function that screen.load would have set
    screen.load()
    love.update(0.1)
    
    lu.assertTrue(update_called, "Update method should be called")
end

function TestScreenOverlay:test_overlay_draw_method_called()
    -- Create test overlay with draw method
    local draw_called = false
    local test_overlay = {
        draw = function() draw_called = true end
    }
    
    screen.add_overlay(test_overlay)
    
    -- Mock the current screen to prevent errors
    screen.screens["test"] = { update = function() end, draw = function() end, resize = function() end }
    screen.current = "test"
    
    -- Call the love.draw function that screen.load would have set
    screen.load()
    love.draw()
    
    lu.assertTrue(draw_called, "Draw method should be called")
end

function TestScreenOverlay:test_overlay_resize_method_called()
    -- Create test overlay with resize method
    local resize_called = false
    local test_overlay = {
        resize = function(w, h) resize_called = true end
    }
    
    screen.add_overlay(test_overlay)
    
    -- Mock the current screen to prevent errors
    screen.screens["test"] = { update = function() end, draw = function() end, resize = function() end }
    screen.current = "test"
    
    -- Call the love.resize function that screen.load would have set
    screen.load()
    love.resize(800, 600)
    
    lu.assertTrue(resize_called, "Resize method should be called")
end

function TestScreenOverlay:test_overlay_method_not_called()
    -- Test overlay without the specific method
    local update_called = false
    local test_overlay = {
        update = function(dt) update_called = true end
        -- No draw method
    }
    
    screen.add_overlay(test_overlay)
    
    -- Mock the current screen to prevent errors
    screen.screens["test"] = { update = function() end, draw = function() end, resize = function() end }
    screen.current = "test"
    
    -- Call the love.draw function that screen.load would have set
    screen.load()
    love.draw()
    
    -- Since overlay doesn't have a draw method, it should not error and update should remain false
    lu.assertFalse(update_called, "Update method should not be called when draw is called")
end

function TestScreenOverlay:test_overlay_parameters_passed_correctly()
    -- Test that parameters are passed correctly
    local received_dt = nil
    local received_w, received_h = nil, nil
    
    local test_overlay = {
        update = function(dt) received_dt = dt end,
        resize = function(w, h) received_w, received_h = w, h end
    }
    
    screen.add_overlay(test_overlay)
    
    -- Mock the current screen to prevent errors
    screen.screens["test"] = { update = function() end, draw = function() end, resize = function() end }
    screen.current = "test"
    
    -- Call the love functions
    screen.load()
    love.update(0.25)
    love.resize(1024, 768)
    
    -- Check parameters
    lu.assertEquals(received_dt, 0.25, "Should pass correct dt parameter")
    lu.assertEquals(received_w, 1024, "Should pass correct width parameter")
    lu.assertEquals(received_h, 768, "Should pass correct height parameter")
end

return TestScreenOverlay 