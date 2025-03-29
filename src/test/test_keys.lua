require("src.base.table")

local lu = require("src.libraries.luaunit")

TestKeys = {}

function TestKeys:setUp()
    package.loaded["src.base.keys"] = nil
    local keys = require("src.base.keys")
    self.keys = keys

    -- Save original function to restore later
    self.original_isDown = love.keyboard.isDown

    -- Create mock keyboard state
    self.pressed_keys = {}

    -- Create reference to self for the closure
    local test_instance = self

    -- Mock love.keyboard.isDown
    love.keyboard.isDown = function(...)
        local keys_to_check = { ... }
        for _, key in ipairs(keys_to_check) do
            if test_instance.pressed_keys[key] then
                return true
            end
        end
        return false
    end
end

-- Clean up after each test
function TestKeys:tearDown()
    -- Unload the keys module
    package.loaded["src.base.keys"] = nil

    -- Restore original function
    love.keyboard.isDown = self.original_isDown
end

-- Test adding a shortcut
function TestKeys:testAddShortcut()
    -- Add a shortcut
    local id = self.keys.add("a", function() end)

    -- Verify shortcut was registered
    lu.assertNotNil(id, "Shortcut ID should not be nil")
    lu.assertNotNil(self.keys.shortcuts[id], "Shortcut should be registered in shortcuts table")
end

-- Test removing a shortcut
function TestKeys:testRemoveShortcut()
    -- Add and then remove a shortcut
    local id = self.keys.add("a", function() end)
    local result = self.keys.remove_shortcut(id)

    -- Verify shortcut was removed
    lu.assertTrue(result, "Remove should return true for success")
    lu.assertNil(self.keys.shortcuts[id], "Shortcut should be removed from shortcuts table")
end

-- Test removing a non-existent shortcut
function TestKeys:testRemoveNonExistentShortcut()
    local result = self.keys.remove_shortcut("non_existent")

    -- Verify operation failed
    lu.assertFalse(result, "Remove should return false for non-existent shortcut")
end

-- Test get_all_shortcuts returns empty table when no shortcuts are registered
function TestKeys:testGetAllShortcutsEmpty()
    -- Act
    local all_shortcuts = self.keys.get_all_shortcuts()

    -- Verify
    lu.assertEquals(#all_shortcuts, 0, "Should return 0 shortcuts when no shortcuts are registered")
end

-- Test get_all_shortcuts
function TestKeys:testGetAllShortcuts()
    -- Add two shortcuts
    self.keys.add("a", function() end, nil, "Test A")
    self.keys.add("b", function() end, { "ctrl" }, "Test B")

    -- Get shortcuts
    local all_shortcuts = self.keys.get_all_shortcuts()

    -- Verify
    lu.assertEquals(#all_shortcuts, 2, "Should return 2 shortcuts")
end

-- Test shortcut invocation with keypressed
function TestKeys:testKeypressInvokesCallback()
    -- Arrange - completely reset the keys module state
    self.keys.shortcuts = {}
    self.keys.interceptors = {}
    self.pressed_keys = {}

    -- Reset our mock for love.keyboard.isDown
    local test_instance = self
    love.keyboard.isDown = function(...)
        local keys_to_check = { ... }
        for _, key in ipairs(keys_to_check) do
            if test_instance.pressed_keys[key] then
                return true
            end
        end
        return false
    end

    -- Setup tracking variable and explicit callback function
    local was_called = false
    local callback_fn = function() was_called = true end

    -- Add a shortcut with our explicit callback function
    self.keys.add("a", callback_fn)

    -- Simulate key press
    local handled = self.keys.keypressed("a")

    -- Verify callback was invoked
    lu.assertTrue(was_called, "Callback should be invoked on key press")
    lu.assertTrue(handled, "keypressed should return true when handled")
end

-- Test keypressed with non-registered key
function TestKeys:testKeypressNonRegisteredKey()
    -- Setup tracking variable
    local was_called = false

    -- Add a shortcut for a different key
    self.keys.add("a", function() was_called = true end)

    -- Simulate key press for a different key
    local handled = self.keys.keypressed("b")

    -- Verify callback was not invoked
    lu.assertFalse(was_called, "Callback should not be invoked for non-registered key")
    lu.assertFalse(handled, "keypressed should return false when not handled")
end

-- Test callback not invoked without required modifier
function TestKeys:testCallbackNotInvokedWithoutModifier()
    -- Arrange
    self.keys.shortcuts = {}
    self.pressed_keys = {}
    local was_called = false
    self.keys.add("x", function() was_called = true end, { "ctrl" })

    -- Act
    self.keys.keypressed("x")

    -- Assert
    lu.assertFalse(was_called, "Callback should not be invoked without required modifier")
end

-- Test keypressed returns false when no shortcut matches
function TestKeys:testKeypressedReturnsFalseWhenNoMatch()
    -- Arrange
    self.keys.shortcuts = {}
    self.pressed_keys = {}
    self.keys.add("x", function() end, { "ctrl" })

    -- Act
    local handled = self.keys.keypressed("x")

    -- Assert
    lu.assertFalse(handled, "keypressed should return false when key doesn't match any shortcut")
end

-- Test callback invoked with required modifier
function TestKeys:testCallbackInvokedWithModifier()
    -- Arrange - make sure to reset the mock
    self.keys.shortcuts = {}
    self.pressed_keys = {}

    -- Reset our mock for love.keyboard.isDown
    local test_instance = self
    love.keyboard.isDown = function(...)
        local keys_to_check = { ... }
        for _, key in ipairs(keys_to_check) do
            if test_instance.pressed_keys[key] then
                return true
            end
        end
        return false
    end

    local was_called = false
    self.keys.add("x", function()
        was_called = true
    end, { "ctrl" })

    -- When testing with modifiers, we need to set both left and right variants
    -- since the keys module checks for both
    self.pressed_keys["lctrl"] = true
    self.pressed_keys["rctrl"] = true

    -- Act
    local result = self.keys.keypressed("x")

    -- Assert
    lu.assertTrue(was_called, "Callback should be invoked with required modifier")
end

-- Test keypressed returns true when shortcut handled
function TestKeys:testKeypressedReturnsTrueWhenShortcutHandled()
    -- Arrange
    self.keys.shortcuts = {}
    self.pressed_keys = {}

    -- Reset our mock for love.keyboard.isDown
    local test_instance = self
    love.keyboard.isDown = function(...)
        local keys_to_check = { ... }
        for _, key in ipairs(keys_to_check) do
            if test_instance.pressed_keys[key] then
                return true
            end
        end
        return false
    end

    self.keys.add("x", function() end, { "ctrl" })

    -- When testing with modifiers, we need to set both left and right variants
    self.pressed_keys["lctrl"] = true
    self.pressed_keys["rctrl"] = true

    -- Act
    local handled = self.keys.keypressed("x")

    -- Assert
    lu.assertTrue(handled, "keypressed should return true when shortcut is handled")
end

-- Test interceptor
function TestKeys:testInterceptor()
    -- Setup tracking variables
    local interceptor_called = false
    local shortcut_called = false

    -- Create interceptor
    local interceptor = {
        keypressed = function(key)
            if key == "a" then
                interceptor_called = true
                return true
            end
            return false
        end
    }

    -- Register interceptor and shortcut
    self.keys.register_interceptor(interceptor)
    self.keys.add("a", function() shortcut_called = true end)

    -- Simulate key press
    local handled = self.keys.keypressed("a")

    -- Verify
    lu.assertTrue(interceptor_called, "Interceptor should be called")
    lu.assertFalse(shortcut_called, "Shortcut should not be called when intercepted")
    lu.assertTrue(handled, "keypressed should return true when handled")
end

-- Test textinput
function TestKeys:testTextinput()
    -- Setup tracking variable
    local was_called = false

    -- Create interceptor
    local interceptor = {
        textinput = function(text)
            if text == "a" then
                was_called = true
                return true
            end
            return false
        end
    }

    -- Register interceptor
    self.keys.register_interceptor(interceptor)

    -- Simulate text input
    local handled = self.keys.textinput("a")

    -- Verify
    lu.assertTrue(was_called, "Interceptor should be called for textinput")
    lu.assertTrue(handled, "textinput should return true when handled")
end

-- Test that keys not handled by an interceptor still pass through to shortcuts
function TestKeys:testInterceptorPassesThroughWhenNotHandled()
    -- Arrange - reset the keys module state
    self.keys.shortcuts = {}
    self.keys.interceptors = {}
    self.pressed_keys = {}
    
    -- Tracking variables
    local shortcut_called = false
    local interceptor_called = false
    
    -- Create a shortcut for the 'f' key
    self.keys.add("f", function() 
        shortcut_called = true 
    end)
    
    -- Create an interceptor that only handles 'a' key but not 'f'
    local interceptor = {
        keypressed = function(key)
            interceptor_called = true
            -- Only handle 'a' key, return false for all others
            if key == "a" then
                return true
            end
            return false
        end
    }
    
    -- Register the interceptor
    self.keys.register_interceptor(interceptor)
    
    -- Act - press the 'f' key which is not handled by the interceptor
    local handled = self.keys.keypressed("f")
    
    -- Assert - With current implementation, shortcuts should be called when interceptor returns false
    lu.assertTrue(interceptor_called, "Interceptor should be called")
    lu.assertTrue(shortcut_called, "Shortcut should be called when interceptor does not handle key (current behavior)")
    lu.assertTrue(handled, "keypressed should return true when shortcut handles it")
end

-- Test that interceptors are checked in order (newest first)
function TestKeys:testInterceptorsCheckedInOrder()
    -- Arrange - reset the keys module state
    self.keys.shortcuts = {}
    self.keys.interceptors = {}
    self.pressed_keys = {}
    
    -- Tracking variables
    local first_interceptor_called = false
    local second_interceptor_called = false
    
    -- Create first interceptor
    local first_interceptor = {
        keypressed = function(key)
            first_interceptor_called = true
            return true -- Always handle
        end
    }
    
    -- Create second interceptor
    local second_interceptor = {
        keypressed = function(key)
            second_interceptor_called = true
            return true -- Always handle
        end
    }
    
    -- Register interceptors (in reverse order since newest added first)
    local first_id = self.keys.register_interceptor(first_interceptor)
    local second_id = self.keys.register_interceptor(second_interceptor)
    
    -- Act - press any key
    self.keys.keypressed("x")
    
    -- Assert - Second interceptor should be called first (newest first)
    lu.assertTrue(second_interceptor_called, "Second interceptor (newest) should be called first")
    lu.assertFalse(first_interceptor_called, "First interceptor should not be called if second handles key")
end

-- Test multiple interceptors with different handling behaviors
function TestKeys:testMultipleInterceptorsWithDifferentHandling()
    -- Arrange - reset the keys module state
    self.keys.shortcuts = {}
    self.keys.interceptors = {}
    self.pressed_keys = {}
    
    -- Tracking variables
    local first_interceptor_called = false
    local second_interceptor_called = false
    local shortcut_called = false
    
    -- Create first interceptor that doesn't handle key
    local first_interceptor = {
        keypressed = function(key)
            first_interceptor_called = true
            return false -- Don't handle
        end
    }
    
    -- Create second interceptor that doesn't handle key
    local second_interceptor = {
        keypressed = function(key)
            second_interceptor_called = true
            return false -- Don't handle
        end
    }
    
    -- Create a shortcut
    self.keys.add("x", function() 
        shortcut_called = true 
    end)
    
    -- Register interceptors (newest first)
    self.keys.register_interceptor(first_interceptor)
    self.keys.register_interceptor(second_interceptor)
    
    -- Act - press key
    local handled = self.keys.keypressed("x")
    
    -- Assert - Both interceptors should be called, then shortcut
    lu.assertTrue(second_interceptor_called, "Second interceptor should be called")
    lu.assertTrue(first_interceptor_called, "First interceptor should be called when second doesn't handle")
    lu.assertTrue(shortcut_called, "Shortcut should be called when no interceptor handles key")
    lu.assertTrue(handled, "keypressed should return true when shortcut handles it")
end

-- Test that selective handling by interceptors works as expected
function TestKeys:testInterceptorSelectiveKeyHandling()
    -- Arrange - reset the keys module state
    self.keys.shortcuts = {}
    self.keys.interceptors = {}
    self.pressed_keys = {}
    
    -- Tracking variables for different keys
    local interceptor_a_called = false
    local interceptor_b_called = false
    local shortcut_a_called = false
    local shortcut_b_called = false
    
    -- Create interceptor that only handles 'a'
    local interceptor = {
        keypressed = function(key)
            if key == "a" then
                interceptor_a_called = true
                return true -- Handle 'a'
            else if key == "b" then
                interceptor_b_called = true
                return false -- Don't handle 'b'
            end
            end
            return false
        end
    }
    
    -- Create shortcuts for 'a' and 'b'
    self.keys.add("a", function() 
        shortcut_a_called = true 
    end)
    self.keys.add("b", function() 
        shortcut_b_called = true 
    end)
    
    -- Register interceptor
    self.keys.register_interceptor(interceptor)
    
    -- Act - press 'a'
    local handled_a = self.keys.keypressed("a")
    
    -- Act - press 'b'
    local handled_b = self.keys.keypressed("b")
    
    -- Assert - Interceptor should handle 'a' but not 'b'
    lu.assertTrue(interceptor_a_called, "Interceptor should be called for 'a'")
    lu.assertTrue(interceptor_b_called, "Interceptor should be called for 'b'")
    lu.assertFalse(shortcut_a_called, "Shortcut 'a' should not be called when interceptor handles 'a'")
    lu.assertTrue(shortcut_b_called, "Shortcut 'b' should be called when interceptor doesn't handle 'b'")
    lu.assertTrue(handled_a, "keypressed should return true when interceptor handles 'a'")
    lu.assertTrue(handled_b, "keypressed should return true when shortcut handles 'b'")
end

-- Test proper unregistration of interceptors
function TestKeys:testInterceptorUnregistration()
    -- Arrange - reset the keys module state
    self.keys.shortcuts = {}
    self.keys.interceptors = {}
    self.pressed_keys = {}
    
    -- Tracking variables
    local interceptor_called = false
    local shortcut_called = false
    
    -- Create interceptor and shortcut for same key
    local interceptor = {
        keypressed = function(key)
            interceptor_called = true
            return true -- Handle all keys
        end
    }
    
    self.keys.add("x", function() 
        shortcut_called = true 
    end)
    
    -- Register interceptor and verify it blocks shortcut
    local id = self.keys.register_interceptor(interceptor)
    self.keys.keypressed("x")
    lu.assertTrue(interceptor_called, "Interceptor should be called")
    lu.assertFalse(shortcut_called, "Shortcut should not be called when interceptor handles key")
    
    -- Reset tracking
    interceptor_called = false
    shortcut_called = false
    
    -- Unregister interceptor
    self.keys.unregister_interceptor(id)
    
    -- Act - press key again
    self.keys.keypressed("x")
    
    -- Assert - Now shortcut should be called
    lu.assertFalse(interceptor_called, "Unregistered interceptor should not be called")
    lu.assertTrue(shortcut_called, "Shortcut should be called when interceptor is unregistered")
end

-- Test removing a shortcut by key
function TestKeys:testRemoveShortcutByKey()
    -- Arrange
    self.keys.add("q", function() end)
    
    -- Act
    local result = self.keys.remove_shortcut_by_key("q")
    
    -- Assert
    lu.assertTrue(result, "Remove by key should return true for success")
end

-- Test removing a shortcut by key with modifiers
function TestKeys:testRemoveShortcutByKeyWithModifiers()
    -- Arrange
    self.keys.add("q", function() end, {"ctrl"})
    
    -- Act
    local result = self.keys.remove_shortcut_by_key("q", {"ctrl"})
    
    -- Assert
    lu.assertTrue(result, "Remove by key with modifiers should return true for success")
end

-- Test removing shortcuts by scope
function TestKeys:testRemoveShortcutsByScope()
    -- Arrange
    self.keys.add("a", function() end, nil, nil, "test_scope")
    self.keys.add("b", function() end, nil, nil, "test_scope")
    self.keys.add("c", function() end, nil, nil, "other_scope")
    
    -- Act
    local removed_count = self.keys.remove_shortcuts_by_scope("test_scope")
    
    -- Assert
    lu.assertEquals(removed_count, 2, "Should remove exactly 2 shortcuts with the scope")
end

-- Test removing shortcuts by scope returns 0 for non-existent scope
function TestKeys:testRemoveShortcutsByNonExistentScope()
    -- Arrange - ensure no shortcuts with this scope exist
    self.keys.remove_shortcuts_by_scope("non_existent_scope")
    
    -- Act
    local removed_count = self.keys.remove_shortcuts_by_scope("non_existent_scope")
    
    -- Assert
    lu.assertEquals(removed_count, 0, "Should return 0 for non-existent scope")
end

-- Test fallback behavior - no modifiers pressed but shortcut defined without modifiers
function TestKeys:testFallbackBehaviorNoModifiers()
    -- Arrange
    local was_called = false
    self.keys.add("z", function() was_called = true end)
    self.pressed_keys = {} -- Ensure no modifiers are pressed
    
    -- Act
    self.keys.keypressed("z")
    
    -- Assert
    lu.assertTrue(was_called, "Shortcut should be called when no modifiers are required or pressed")
end

-- Test that when modifiers are pressed but shortcut doesn't require them, it doesn't trigger
function TestKeys:testNoFallbackWhenModifiersPressed()
    -- Arrange
    local was_called = false
    self.keys.add("z", function() was_called = true end) -- No modifiers
    self.pressed_keys["lctrl"] = true -- But ctrl is pressed
    
    -- Act
    local result = self.keys.keypressed("z")
    
    -- Assert
    lu.assertFalse(was_called, "Shortcut without modifiers should not be called when modifiers are pressed")
end

-- Test that textinput returns false when no interceptor handles it
function TestKeys:testTextinputReturnsFalseWhenNoHandler()
    -- Arrange
    self.keys.interceptors = {} -- Ensure no interceptors
    
    -- Act
    local result = self.keys.textinput("a")
    
    -- Assert
    lu.assertFalse(result, "textinput should return false when no interceptors handle it")
end

-- Test that add() and add_shortcut() functions are compatible
function TestKeys:testAddAndAddShortcutCompatibility()
    -- Arrange
    self.keys.shortcuts = {}
    local callback1 = function() end
    local callback2 = function() end
    
    -- Act
    local key1 = self.keys.add("a", callback1, {"ctrl"}, "desc1", "scope1")
    local key2 = self.keys.add_shortcut("b", {
        callback = callback2,
        modifiers = {"shift"},
        description = "desc2",
        scope = "scope2"
    })
    
    -- Assert
    lu.assertNotNil(self.keys.shortcuts[key1], "Shortcut added with add() should be registered")
    lu.assertNotNil(self.keys.shortcuts[key2], "Shortcut added with add_shortcut() should be registered")
end

-- Test multiple modifiers combinations
function TestKeys:testMultipleModifierCombinations()
    -- Arrange
    local ctrl_shift_called = false
    local only_ctrl_called = false
    
    self.keys.add("m", function() only_ctrl_called = true end, {"ctrl"})
    self.keys.add("m", function() ctrl_shift_called = true end, {"ctrl", "shift"})
    
    -- Set up ctrl+shift+m pressed
    self.pressed_keys["lctrl"] = true
    self.pressed_keys["lshift"] = true
    
    -- Act
    self.keys.keypressed("m")
    
    -- Assert
    lu.assertTrue(ctrl_shift_called, "Shortcut with ctrl+shift should be called when both modifiers are pressed")
    lu.assertFalse(only_ctrl_called, "Shortcut with only ctrl should not be called when ctrl+shift is pressed")
end

-- Test that specific shortcut is triggered when multiple shortcuts have the same key with different modifiers
function TestKeys:testCorrectShortcutTriggeredWithModifiers()
    -- Arrange
    local no_modifier_called = false
    local ctrl_called = false
    local alt_called = false
    
    self.keys.add("x", function() no_modifier_called = true end)
    self.keys.add("x", function() ctrl_called = true end, {"ctrl"})
    self.keys.add("x", function() alt_called = true end, {"alt"})
    
    -- Set up only ctrl pressed
    self.pressed_keys["lctrl"] = true
    
    -- Act
    self.keys.keypressed("x")
    
    -- Assert
    lu.assertTrue(ctrl_called, "Shortcut with ctrl should be called when ctrl is pressed")
    lu.assertFalse(no_modifier_called, "Shortcut without modifiers should not be called when ctrl is pressed")
    lu.assertFalse(alt_called, "Shortcut with alt should not be called when ctrl is pressed")
end
