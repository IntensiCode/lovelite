local m = {}

---Clamps a value between a minimum and maximum value
---@param value number The value to clamp
---@param min number The minimum value
---@param max number The maximum value
---@return number The clamped value
function m.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

return m 