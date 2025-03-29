local lu = require("src.libraries.luaunit")

-- Test module (this would typically be in your actual code)
local mathUtils = {}

function mathUtils.add(a, b)
    return a + b
end

function mathUtils.multiply(a, b)
    return a * b
end

-- Test cases
TestMathUtils = {}

function TestMathUtils:testAdd()
    lu.assertEquals(mathUtils.add(1, 1), 2)
    lu.assertEquals(mathUtils.add(-1, 1), 0)
    lu.assertEquals(mathUtils.add(5, 7), 12)
end

function TestMathUtils:testMultiply()
    lu.assertEquals(mathUtils.multiply(2, 3), 6)
    lu.assertEquals(mathUtils.multiply(0, 5), 0)
    lu.assertEquals(mathUtils.multiply(-2, 3), -6)
end

-- Run the tests
if not love then
    -- Only run tests directly if not in LÖVE context
    os.exit(lu.LuaUnit.run())
else
    -- When running in LÖVE, return the test suite
    return {
        run = function()
            return lu.LuaUnit.run()
        end
    }
end 