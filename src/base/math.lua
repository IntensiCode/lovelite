---Clamp and round extensions for the math library

---Clamps a value between a minimum and maximum value
---@param value number The value to clamp
---@param min number The minimum value
---@param max number The maximum value
---@return number The clamped value
function math.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

---Rounds a number to the nearest integer
---@param value number The value to round
---@return number The rounded value
function math.round(value)
    return math.floor(value + 0.5)
end 