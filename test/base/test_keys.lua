require("src.base.table")

local lu = require("src.libraries.luaunit")

test_keys = {}

function test_keys:setup()
    package.loaded["src.base.keys"] = nil
    local keys = require("src.base.keys")

    -- Store shortcuts for testing
    self.keys = keys

    -- Default mock used to check if callbacks were invoked
    self.callback_invoked = false
    self.default_callback = function()
        self.callback_invoked = true
    end

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
function test_keys:teardown()
    -- Unload the keys module
    package.loaded["src.base.keys"] = nil

    -- Restore original function
    love.keyboard.isDown = self.original_isDown
end

-- Test adding a shortcut
function test_keys:test_add_shortcut()
    -- Add a shortcut
    local id = self.keys.add("a", function() end)

    -- Verify shortcut was added
    local shortcuts = self.keys.get_all_shortcuts()
    lu.assertEquals(#shortcuts, 1, "One shortcut should be added")
    lu.assertNotNil(id, "Add should return an ID")
end

-- Test removing a shortcut
function test_keys:test_remove_shortcut()
    -- Add and then remove a shortcut
    local id = self.keys.add("a", function() end)
    local result = self.keys.remove_shortcut(id)

    -- Verify shortcut was removed
    lu.assertTrue(result, "Remove should return true for existing shortcut")
    local shortcuts = self.keys.get_all_shortcuts()
    lu.assertEquals(#shortcuts, 0, "No shortcuts should remain")
end

-- Test removing a non-existent shortcut
function test_keys:test_remove_non_existent_shortcut()
    local result = self.keys.remove_shortcut("non_existent")

    -- Verify it returns false
    lu.assertFalse(result, "Remove should return false for non-existent shortcut")
end

-- Test get_all_shortcuts returns empty table when no shortcuts are registered
function test_keys:test_get_all_shortcuts_empty()
    -- Act
    local all_shortcuts = self.keys.get_all_shortcuts()

    -- Assert
    lu.assertNotNil(all_shortcuts, "Should return a table even when empty")
    lu.assertEquals(#all_shortcuts, 0, "Table should be empty")
end

-- Test get_all_shortcuts
function test_keys:test_get_all_shortcuts()
    -- Add two shortcuts
    self.keys.add("a", function() end, nil, "Test A")
    self.keys.add("b", function() end, nil, "Test B")

    -- Get all shortcuts
    local all_shortcuts = self.keys.get_all_shortcuts()

    -- Verify correct count
    lu.assertEquals(#all_shortcuts, 2, "Should have 2 shortcuts")

    -- Find shortcuts by key since order is not guaranteed
    local shortcut_a = nil
    local shortcut_b = nil
    for _, shortcut in ipairs(all_shortcuts) do
        if shortcut.key == "a" then
            shortcut_a = shortcut
        elseif shortcut.key == "b" then
            shortcut_b = shortcut
        end
    end

    -- Verify shortcut details
    lu.assertNotNil(shortcut_a, "Shortcut with key 'a' should exist")
    lu.assertNotNil(shortcut_b, "Shortcut with key 'b' should exist")
    lu.assertEquals(
        shortcut_a.description,
        "Test A",
        "Shortcut 'a' should have description 'Test A'"
    )
    lu.assertEquals(
        shortcut_b.description,
        "Test B",
        "Shortcut 'b' should have description 'Test B'"
    )
end

-- Test shortcut invocation with keypressed
function test_keys:test_keypress_invokes_callback()
    -- Arrange - completely reset the keys module state
    self.keys.shortcuts = {}
    self.callback_invoked = false

    -- Add a shortcut and store its state
    self.keys.add("a", self.default_callback)

    -- Simulate keypressed event
    local was_handled = self.keys.keypressed("a", "a", false)

    -- Verify callback was invoked
    lu.assertTrue(self.callback_invoked, "Callback should be invoked")
    lu.assertTrue(was_handled, "keypressed should return true when a shortcut is handled")
end

-- Test keypressed with non-registered key
function test_keys:test_keypress_non_registered_key()
    -- Setup tracking variable
    local was_called = false

    -- Add a shortcut for a different key
    self.keys.add("a", function()
        was_called = true
    end)

    -- Simulate key press for a different key
    local handled = self.keys.keypressed("b")

    -- Verify callback was not invoked
    lu.assertFalse(was_called, "Callback should not be invoked for non-registered key")
    lu.assertFalse(handled, "keypressed should return false when not handled")
end

-- Test callback not invoked without required modifier
function test_keys:test_callback_not_invoked_without_modifier()
    -- Arrange
    self.keys.shortcuts = {}
    self.pressed_keys = {}
    local was_called = false
    self.keys.add("x", function()
        was_called = true
    end, { "ctrl" })

    -- Act
    self.keys.keypressed("x")

    -- Assert
    lu.assertFalse(was_called, "Callback should not be invoked without required modifier")
end

-- Test keypressed returns false when no shortcut matches
function test_keys:test_keypressed_returns_false_when_no_match()
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
function test_keys:test_callback_invoked_with_modifier()
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
function test_keys:test_keypressed_returns_true_when_shortcut_handled()
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
function test_keys:test_interceptor()
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
        end,
    }

    -- Register interceptor and shortcut
    self.keys.register_interceptor(interceptor)
    self.keys.add("a", function()
        shortcut_called = true
    end)

    -- Simulate key press
    local handled = self.keys.keypressed("a")

    -- Verify
    lu.assertTrue(interceptor_called, "Interceptor should be called")
    lu.assertFalse(shortcut_called, "Shortcut should not be called when intercepted")
    lu.assertTrue(handled, "keypressed should return true when handled")
end

-- Test textinput
function test_keys:test_textinput()
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
        end,
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
function test_keys:test_interceptor_passes_through_when_not_handled()
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
        end,
    }

    -- Register the interceptor
    self.keys.register_interceptor(interceptor)

    -- Act - press the 'f' key which is not handled by the interceptor
    local handled = self.keys.keypressed("f")

    -- Assert - With current implementation, shortcuts should be called when interceptor returns false
    lu.assertTrue(interceptor_called, "Interceptor should be called")
    lu.assertTrue(
        shortcut_called,
        "Shortcut should be called when interceptor does not handle key (current behavior)"
    )
    lu.assertTrue(handled, "keypressed should return true when shortcut handles it")
end

-- Test that interceptors are checked in order (newest first)
function test_keys:test_interceptors_checked_in_order()
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
        end,
    }

    -- Create second interceptor
    local second_interceptor = {
        keypressed = function(key)
            second_interceptor_called = true
            return true -- Always handle
        end,
    }

    -- Register interceptors (in reverse order since newest added first)
    local first_id = self.keys.register_interceptor(first_interceptor)
    local second_id = self.keys.register_interceptor(second_interceptor)

    -- Act - press any key
    self.keys.keypressed("x")

    -- Assert - Second interceptor should be called first (newest first)
    lu.assertTrue(second_interceptor_called, "Second interceptor (newest) should be called first")
    lu.assertFalse(
        first_interceptor_called,
        "First interceptor should not be called if second handles key"
    )
end

-- Test multiple interceptors with different handling behaviors
function test_keys:test_multiple_interceptors_with_different_handling()
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
        end,
    }

    -- Create second interceptor that doesn't handle key
    local second_interceptor = {
        keypressed = function(key)
            second_interceptor_called = true
            return false -- Don't handle
        end,
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
    lu.assertTrue(
        first_interceptor_called,
        "First interceptor should be called when second doesn't handle"
    )
    lu.assertTrue(shortcut_called, "Shortcut should be called when no interceptor handles key")
    lu.assertTrue(handled, "keypressed should return true when shortcut handles it")
end

-- Test that selective handling by interceptors works as expected
function test_keys:test_interceptor_selective_key_handling()
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
            else
                if key == "b" then
                    interceptor_b_called = true
                    return false -- Don't handle 'b'
                end
            end
            return false
        end,
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
    lu.assertFalse(
        shortcut_a_called,
        "Shortcut 'a' should not be called when interceptor handles 'a'"
    )
    lu.assertTrue(
        shortcut_b_called,
        "Shortcut 'b' should be called when interceptor doesn't handle 'b'"
    )
    lu.assertTrue(handled_a, "keypressed should return true when interceptor handles 'a'")
    lu.assertTrue(handled_b, "keypressed should return true when shortcut handles 'b'")
end

-- Test proper unregistration of interceptors
function test_keys:test_interceptor_unregistration()
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
        end,
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
function test_keys:test_remove_shortcut_by_key()
    -- Arrange
    self.keys.add("q", function() end)

    -- Act
    local result = self.keys.remove_shortcut_by_key("q")

    -- Assert
    lu.assertTrue(result, "Remove by key should return true for success")
end

-- Test removing a shortcut by key with modifiers
function test_keys:test_remove_shortcut_by_key_with_modifiers()
    -- Arrange
    self.keys.add("q", function() end, { "ctrl" })

    -- Act
    local result = self.keys.remove_shortcut_by_key("q", { "ctrl" })

    -- Assert
    lu.assertTrue(result, "Remove by key with modifiers should return true for success")
end

-- Test removing shortcuts by scope
function test_keys:test_remove_shortcuts_by_scope()
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
function test_keys:test_remove_shortcuts_by_non_existent_scope()
    -- Arrange - ensure no shortcuts with this scope exist
    self.keys.remove_shortcuts_by_scope("non_existent_scope")

    -- Act
    local removed_count = self.keys.remove_shortcuts_by_scope("non_existent_scope")

    -- Assert
    lu.assertEquals(removed_count, 0, "Should return 0 for non-existent scope")
end

-- Test fallback behavior - no modifiers pressed but shortcut defined without modifiers
function test_keys:test_fallback_behavior_no_modifiers()
    -- Arrange
    local was_called = false
    self.keys.add("z", function()
        was_called = true
    end)
    self.pressed_keys = {} -- Ensure no modifiers are pressed

    -- Act
    self.keys.keypressed("z")

    -- Assert
    lu.assertTrue(was_called, "Shortcut should be called when no modifiers are required or pressed")
end

-- Test that when modifiers are pressed but shortcut doesn't require them, it doesn't trigger
function test_keys:test_no_fallback_when_modifiers_pressed()
    -- Arrange
    local was_called = false
    self.keys.add("z", function()
        was_called = true
    end) -- No modifiers
    self.pressed_keys["lctrl"] = true -- But ctrl is pressed

    -- Act
    local result = self.keys.keypressed("z")

    -- Assert
    lu.assertFalse(
        was_called,
        "Shortcut without modifiers should not be called when modifiers are pressed"
    )
end

-- Test that textinput returns false when no interceptor handles it
function test_keys:test_textinput_returns_false_when_no_handler()
    -- Arrange
    self.keys.interceptors = {} -- Ensure no interceptors

    -- Act
    local result = self.keys.textinput("a")

    -- Assert
    lu.assertFalse(result, "textinput should return false when no interceptors handle it")
end

-- Test that add() and add_shortcut() functions are compatible
function test_keys:test_add_and_add_shortcut_compatibility()
    -- Arrange
    self.keys.shortcuts = {}
    local callback1 = function() end
    local callback2 = function() end

    -- Act
    local key1 = self.keys.add("a", callback1, { "ctrl" }, "desc1", "scope1")
    local key2 = self.keys.add_shortcut("b", {
        callback = callback2,
        modifiers = { "shift" },
        description = "desc2",
        scope = "scope2",
    })

    -- Assert
    lu.assertNotNil(self.keys.shortcuts[key1], "Shortcut added with add() should be registered")
    lu.assertNotNil(
        self.keys.shortcuts[key2],
        "Shortcut added with add_shortcut() should be registered"
    )
end

-- Test multiple modifiers combinations
function test_keys:test_multiple_modifier_combinations()
    -- Arrange
    local ctrl_shift_called = false
    local only_ctrl_called = false

    self.keys.add("m", function()
        only_ctrl_called = true
    end, { "ctrl" })
    self.keys.add("m", function()
        ctrl_shift_called = true
    end, { "ctrl", "shift" })

    -- Set up ctrl+shift+m pressed
    self.pressed_keys["lctrl"] = true
    self.pressed_keys["lshift"] = true

    -- Act
    self.keys.keypressed("m")

    -- Assert
    lu.assertTrue(
        ctrl_shift_called,
        "Shortcut with ctrl+shift should be called when both modifiers are pressed"
    )
    lu.assertFalse(
        only_ctrl_called,
        "Shortcut with only ctrl should not be called when ctrl+shift is pressed"
    )
end

-- Test that specific shortcut is triggered when multiple shortcuts have the same key with different modifiers
function test_keys:test_correct_shortcut_triggered_with_modifiers()
    -- Arrange
    local no_modifier_called = false
    local ctrl_called = false
    local alt_called = false

    self.keys.add("x", function()
        no_modifier_called = true
    end)
    self.keys.add("x", function()
        ctrl_called = true
    end, { "ctrl" })
    self.keys.add("x", function()
        alt_called = true
    end, { "alt" })

    -- Set up only ctrl pressed
    self.pressed_keys["lctrl"] = true

    -- Act
    self.keys.keypressed("x")

    -- Assert
    lu.assertTrue(ctrl_called, "Shortcut with ctrl should be called when ctrl is pressed")
    lu.assertFalse(
        no_modifier_called,
        "Shortcut without modifiers should not be called when ctrl is pressed"
    )
    lu.assertFalse(alt_called, "Shortcut with alt should not be called when ctrl is pressed")
end
