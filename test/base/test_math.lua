local lu = require("src.libraries.luaunit")
require("src.base.math")

-- Test cases for math extensions
test_math_extensions = {}

function test_math_extensions:test_clamp()
    -- Test normal clamping
    lu.assertEquals(math.clamp(5, 0, 10), 5)
    lu.assertEquals(math.clamp(-5, 0, 10), 0)
    lu.assertEquals(math.clamp(15, 0, 10), 10)

    -- Test with decimal values
    lu.assertEquals(math.clamp(3.5, 2.5, 4.5), 3.5)
    lu.assertEquals(math.clamp(1.5, 2.5, 4.5), 2.5)
    lu.assertEquals(math.clamp(5.5, 2.5, 4.5), 4.5)

    -- Test with negative values
    lu.assertEquals(math.clamp(-5, -10, -1), -5)
    lu.assertEquals(math.clamp(-15, -10, -1), -10)
    lu.assertEquals(math.clamp(0, -10, -1), -1)
end

function test_math_extensions:test_round()
    -- Test rounding integers
    lu.assertEquals(math.round(5), 5)
    lu.assertEquals(math.round(-5), -5)

    -- Test rounding up
    lu.assertEquals(math.round(5.6), 6)
    lu.assertEquals(math.round(5.5), 6)

    -- Test rounding down
    lu.assertEquals(math.round(5.4), 5)
    lu.assertEquals(math.round(5.1), 5)

    -- Test with negative values
    lu.assertEquals(math.round(-5.6), -6)
    lu.assertEquals(math.round(-5.5), -5) -- Note: math.floor rounds differently for negatives
    lu.assertEquals(math.round(-5.4), -5)
end

return test_math_extensions
