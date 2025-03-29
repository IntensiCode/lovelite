local lu = require("src.libraries.luaunit")

-- Test module
local stringUtils = {}

function stringUtils.concat(a, b)
    return a .. b
end

function stringUtils.split(str, sep)
    local result = {}
    local pattern = string.format("([^%s]+)", sep)
    for segment in string.gmatch(str, pattern) do
        table.insert(result, segment)
    end
    return result
end

-- Test cases
TestStringUtils = {}

function TestStringUtils:testConcat()
    lu.assertEquals(stringUtils.concat("Hello", " World"), "Hello World")
    lu.assertEquals(stringUtils.concat("", "Empty"), "Empty")
    lu.assertEquals(stringUtils.concat("123", "456"), "123456")
end

function TestStringUtils:testSplit()
    lu.assertEquals(stringUtils.split("a,b,c", ","), {"a", "b", "c"})
    lu.assertEquals(stringUtils.split("one word", " "), {"one", "word"})
    lu.assertEquals(stringUtils.split("nodelimiter", "-"), {"nodelimiter"})
end

return TestStringUtils 