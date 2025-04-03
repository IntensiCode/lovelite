local lu = require("src.libraries.luaunit")
local pos = require("src.base.pos")

-- Test cases for the pos (position) module
test_pos = {}

function test_pos:test_new()
    -- Test creating a new position
    local p = pos.new(3, 4)
    lu.assertEquals(p.x, 3)
    lu.assertEquals(p.y, 4)

    -- Test creating with zeros
    local zero = pos.new(0, 0)
    lu.assertEquals(zero.x, 0)
    lu.assertEquals(zero.y, 0)

    -- Test creating with negative values
    local neg = pos.new(-5, -10)
    lu.assertEquals(neg.x, -5)
    lu.assertEquals(neg.y, -10)
end

function test_pos:test_addition()
    -- Test normal addition
    local a = pos.new(3, 4)
    local b = pos.new(2, 5)
    local result = a + b
    lu.assertEquals(result.x, 5)
    lu.assertEquals(result.y, 9)

    -- Test with zero
    local c = pos.new(0, 0)
    result = a + c
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 4)

    -- Test with negative values
    local d = pos.new(-1, -2)
    result = a + d
    lu.assertEquals(result.x, 2)
    lu.assertEquals(result.y, 2)
end

function test_pos:test_subtraction()
    -- Test normal subtraction
    local a = pos.new(5, 8)
    local b = pos.new(2, 3)
    local result = a - b
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 5)

    -- Test with zero
    local c = pos.new(0, 0)
    result = a - c
    lu.assertEquals(result.x, 5)
    lu.assertEquals(result.y, 8)

    -- Test with negative values
    local d = pos.new(-1, -2)
    result = a - d
    lu.assertEquals(result.x, 6)
    lu.assertEquals(result.y, 10)
end

function test_pos:test_multiplication()
    -- Test multiplication with a scalar
    local a = pos.new(3, 4)
    local result = a * 2
    lu.assertEquals(result.x, 6)
    lu.assertEquals(result.y, 8)

    -- Test with zero
    result = a * 0
    lu.assertEquals(result.x, 0)
    lu.assertEquals(result.y, 0)

    -- Test with negative scalar
    result = a * -1
    lu.assertEquals(result.x, -3)
    lu.assertEquals(result.y, -4)

    -- Test element-wise multiplication
    local b = pos.new(2, 5)
    result = a * b
    lu.assertEquals(result.x, 6)
    lu.assertEquals(result.y, 20)
end

function test_pos:test_division()
    -- Test division with a scalar
    local a = pos.new(6, 8)
    local result = a / 2
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 4)

    -- Test with negative scalar
    result = a / -2
    lu.assertEquals(result.x, -3)
    lu.assertEquals(result.y, -4)

    -- Test element-wise division
    local b = pos.new(2, 4)
    result = a / b
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 2)
end

function test_pos:test_length()
    -- Test Pythagorean length calculation
    local a = pos.new(3, 4)
    lu.assertEquals(a:length(), 5)

    -- Test with zero
    local zero = pos.new(0, 0)
    lu.assertEquals(zero:length(), 0)

    -- Test with negative values
    local neg = pos.new(-3, -4)
    lu.assertEquals(neg:length(), 5)
end

function test_pos:test_normalize()
    -- Test normalization - should result in a unit vector
    local a = pos.new(3, 4)
    local norm = a:normalize()

    -- Expect results to be 3/5 and 4/5
    lu.assertAlmostEquals(norm.x, 0.6, 0.0001)
    lu.assertAlmostEquals(norm.y, 0.8, 0.0001)

    -- Length of normalized vector should be 1
    lu.assertAlmostEquals(norm:length(), 1, 0.0001)
end

function test_pos:test_normalized()
    -- Test normalized function - should handle zero vector
    local zero = pos.new(0, 0)
    local result = zero:normalized()
    lu.assertEquals(result.x, 0)
    lu.assertEquals(result.y, 0)

    -- Test with non-zero vector
    local a = pos.new(3, 4)
    local norm = a:normalized()
    lu.assertAlmostEquals(norm.x, 0.6, 0.0001)
    lu.assertAlmostEquals(norm.y, 0.8, 0.0001)
end

function test_pos:test_dot()
    -- Test dot product
    local a = pos.new(3, 4)
    local b = pos.new(2, 5)
    lu.assertEquals(a:dot(b), 3 * 2 + 4 * 5)

    -- Test with zero
    local zero = pos.new(0, 0)
    lu.assertEquals(a:dot(zero), 0)

    -- Test with perpendicular vectors
    local perp = pos.new(4, -3) -- Perpendicular to (3,4)
    lu.assertEquals(a:dot(perp), 0)
end

function test_pos:test_distance()
    -- Test distance calculation
    local a = pos.new(1, 1)
    local b = pos.new(4, 5)
    lu.assertEquals(a:distance(b), 5)

    -- Distance should be symmetric
    lu.assertEquals(a:distance(b), b:distance(a))

    -- Distance to self should be 0
    lu.assertEquals(a:distance(a), 0)
end

function test_pos:test_rotate()
    -- Test rotation by 90 degrees
    local a = pos.new(1, 0)
    local rotated = a:rotate(math.pi / 2) -- 90 degrees clockwise
    lu.assertAlmostEquals(rotated.x, 0, 0.0001)
    lu.assertAlmostEquals(rotated.y, 1, 0.0001)

    -- Test rotation by 180 degrees
    rotated = a:rotate(math.pi) -- 180 degrees
    lu.assertAlmostEquals(rotated.x, -1, 0.0001)
    lu.assertAlmostEquals(rotated.y, 0, 0.0001)

    -- Test rotation by 360 degrees (should return to original)
    rotated = a:rotate(2 * math.pi) -- 360 degrees
    lu.assertAlmostEquals(rotated.x, 1, 0.0001)
    lu.assertAlmostEquals(rotated.y, 0, 0.0001)
end

function test_pos:test_round()
    -- Test rounding
    local a = pos.new(3.3, 4.7)
    local rounded = a:round()
    lu.assertEquals(rounded.x, 3)
    lu.assertEquals(rounded.y, 5)

    -- Test negative values
    local neg = pos.new(-2.7, -3.2)
    rounded = neg:round()
    lu.assertEquals(rounded.x, -3)
    lu.assertEquals(rounded.y, -3)
end

function test_pos:test_floor()
    -- Test floor function
    local a = pos.new(3.7, 4.2)
    local floored = a:floor()
    lu.assertEquals(floored.x, 3)
    lu.assertEquals(floored.y, 4)

    -- Test negative values
    local neg = pos.new(-2.3, -3.8)
    floored = neg:floor()
    lu.assertEquals(floored.x, -3)
    lu.assertEquals(floored.y, -4)
end

function test_pos:test_ceil()
    -- Test ceiling function
    local a = pos.new(3.3, 4.7)
    local ceiled = a:ceil()
    lu.assertEquals(ceiled.x, 4)
    lu.assertEquals(ceiled.y, 5)

    -- Test negative values
    local neg = pos.new(-2.7, -3.2)
    ceiled = neg:ceil()
    lu.assertEquals(ceiled.x, -2)
    lu.assertEquals(ceiled.y, -3)
end

function test_pos:test_abs()
    -- Test absolute value
    local a = pos.new(-3, 4)
    local result = a:abs()
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 4)

    -- Test with all negative values
    local neg = pos.new(-5, -10)
    result = neg:abs()
    lu.assertEquals(result.x, 5)
    lu.assertEquals(result.y, 10)

    -- Test with zero
    local zero = pos.new(0, 0)
    result = zero:abs()
    lu.assertEquals(result.x, 0)
    lu.assertEquals(result.y, 0)
end

function test_pos:test_min()
    -- Test min function
    local a = pos.new(3, 7)
    local b = pos.new(5, 2)
    local result = a:min(b)
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 2)

    -- Test with negative values
    local neg = pos.new(-10, -5)
    result = a:min(neg)
    lu.assertEquals(result.x, -10)
    lu.assertEquals(result.y, -5)
end

function test_pos:test_max()
    -- Test max function
    local a = pos.new(3, 7)
    local b = pos.new(5, 2)
    local result = a:max(b)
    lu.assertEquals(result.x, 5)
    lu.assertEquals(result.y, 7)

    -- Test with negative values
    local neg = pos.new(-10, -5)
    result = a:max(neg)
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 7)
end

function test_pos:test_clamp()
    -- Test clamping
    local a = pos.new(3, 7)
    local min = pos.new(2, 6)
    local max = pos.new(4, 8)
    local result = a:clamp(min, max)
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 7)

    -- Test clamping that clamps x
    local outside_x = pos.new(1, 7)
    result = outside_x:clamp(min, max)
    lu.assertEquals(result.x, 2)
    lu.assertEquals(result.y, 7)

    -- Test clamping that clamps y
    local outside_y = pos.new(3, 9)
    result = outside_y:clamp(min, max)
    lu.assertEquals(result.x, 3)
    lu.assertEquals(result.y, 8)
end

function test_pos:test_lerp()
    -- Test linear interpolation
    local a = pos.new(0, 0)
    local b = pos.new(10, 20)

    -- Test at t=0 (should be equal to a)
    local result = a:lerp(b, 0)
    lu.assertEquals(result.x, 0)
    lu.assertEquals(result.y, 0)

    -- Test at t=1 (should be equal to b)
    result = a:lerp(b, 1)
    lu.assertEquals(result.x, 10)
    lu.assertEquals(result.y, 20)

    -- Test at t=0.5 (should be halfway)
    result = a:lerp(b, 0.5)
    lu.assertEquals(result.x, 5)
    lu.assertEquals(result.y, 10)

    -- Test at t=0.25
    result = a:lerp(b, 0.25)
    lu.assertEquals(result.x, 2.5)
    lu.assertEquals(result.y, 5)
end

function test_pos:test_unpack()
    -- Test unpacking coordinates
    local a = pos.new(3, 4)
    local x, y = a:unpack()
    lu.assertEquals(x, 3)
    lu.assertEquals(y, 4)
end

function test_pos:test_to_string()
    -- Test string representation
    local a = pos.new(3, 4)
    local str = tostring(a)
    lu.assertEquals(str, "pos(3.000, 4.000)")

    -- Test with decimal values
    local dec = pos.new(3.14159, 2.71828)
    str = tostring(dec)
    lu.assertEquals(str, "pos(3.142, 2.718)") -- Should round to 3 decimal places
end

return test_pos
