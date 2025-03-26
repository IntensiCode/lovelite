---@class Vector2
---@field x number
---@field y number
local Vector2 = {
    x = 0,
    y = 0
}
Vector2.__index = Vector2

---@param x number
---@param y number
---@return Vector2
function Vector2.new(x, y)
    local v = setmetatable({}, Vector2)
    v.x = x
    v.y = y
    return v
end

---@param a Vector2
---@param b Vector2
---@return Vector2
function Vector2.__add(a, b)
    assert(a ~= nil and b ~= nil, "Cannot add nil vectors")
    assert(type(a) == "table" and type(b) == "table", "Can only add Vector2 objects")
    return Vector2.new(a.x + b.x, a.y + b.y)
end

---@param a Vector2
---@param b Vector2
---@return Vector2
function Vector2.__sub(a, b)
    assert(a ~= nil and b ~= nil, "Cannot subtract nil vectors")
    assert(type(a) == "table" and type(b) == "table", "Can only subtract Vector2 objects")
    return Vector2.new(a.x - b.x, a.y - b.y)
end

---@param a Vector2
---@param b number|Vector2
---@return Vector2
function Vector2.__mul(a, b)
    assert(a ~= nil, "Cannot multiply nil vector")
    assert(type(a) == "table", "Can only multiply Vector2 objects")
    if type(b) == "number" then
        return Vector2.new(a.x * b, a.y * b)
    else
        assert(b ~= nil, "Cannot multiply by nil")
        assert(type(b) == "table", "Can only multiply by Vector2 or number")
        return Vector2.new(a.x * b.x, a.y * b.y)
    end
end

---@param a Vector2
---@param b number|Vector2
---@return Vector2
function Vector2.__div(a, b)
    assert(a ~= nil, "Cannot divide nil vector")
    assert(type(a) == "table", "Can only divide Vector2 objects")
    if type(b) == "number" then
        assert(b ~= 0, "Cannot divide by zero")
        return Vector2.new(a.x / b, a.y / b)
    else
        assert(b ~= nil, "Cannot divide by nil")
        assert(type(b) == "table", "Can only divide by Vector2 or number")
        assert(b.x ~= 0 and b.y ~= 0, "Cannot divide by zero")
        return Vector2.new(a.x / b.x, a.y / b.y)
    end
end

---@param a Vector2
---@return number
function Vector2:length()
    assert(self ~= nil, "Cannot get length of nil vector")
    assert(type(self) == "table", "Can only get length of Vector2 object")
    return math.sqrt(self.x * self.x + self.y * self.y)
end

---@param a Vector2
---@return Vector2
function Vector2:normalize()
    assert(self ~= nil, "Cannot normalize nil vector")
    assert(type(self) == "table", "Can only normalize Vector2 object")
    local len = self:length()
    assert(len ~= 0, "Cannot normalize zero vector")
    return Vector2.new(self.x / len, self.y / len)
end

---@param a Vector2
---@param b Vector2
---@return number
function Vector2:dot(b)
    assert(self ~= nil and b ~= nil, "Cannot dot product with nil vector")
    assert(type(self) == "table" and type(b) == "table", "Can only dot product Vector2 objects")
    return self.x * b.x + self.y * b.y
end

---@param a Vector2
---@param b Vector2
---@return number
function Vector2:distance(b)
    assert(self ~= nil and b ~= nil, "Cannot get distance to nil vector")
    assert(type(self) == "table" and type(b) == "table", "Can only get distance between Vector2 objects")
    return (b - self):length()
end

---@param a Vector2
---@return Vector2
function Vector2:rotate(angle)
    assert(self ~= nil, "Cannot rotate nil vector")
    assert(type(self) == "table", "Can only rotate Vector2 object")
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    return Vector2.new(
        self.x * cos - self.y * sin,
        self.x * sin + self.y * cos
    )
end

---@param a Vector2
---@return Vector2
function Vector2:round()
    assert(self ~= nil, "Cannot round nil vector")
    assert(type(self) == "table", "Can only round Vector2 object")
    return Vector2.new(math.floor(self.x + 0.5), math.floor(self.y + 0.5))
end

---@param a Vector2
---@return Vector2
function Vector2:floor()
    assert(self ~= nil, "Cannot floor nil vector")
    assert(type(self) == "table", "Can only floor Vector2 object")
    return Vector2.new(math.floor(self.x), math.floor(self.y))
end

---@param a Vector2
---@return Vector2
function Vector2:ceil()
    assert(self ~= nil, "Cannot ceil nil vector")
    assert(type(self) == "table", "Can only ceil Vector2 object")
    return Vector2.new(math.ceil(self.x), math.ceil(self.y))
end

---@param a Vector2
---@return Vector2
function Vector2:abs()
    assert(self ~= nil, "Cannot get absolute value of nil vector")
    assert(type(self) == "table", "Can only get absolute value of Vector2 object")
    return Vector2.new(math.abs(self.x), math.abs(self.y))
end

---@param a Vector2
---@return Vector2
function Vector2:min(b)
    assert(self ~= nil and b ~= nil, "Cannot get minimum with nil vector")
    assert(type(self) == "table" and type(b) == "table", "Can only get minimum of Vector2 objects")
    return Vector2.new(math.min(self.x, b.x), math.min(self.y, b.y))
end

---@param a Vector2
---@return Vector2
function Vector2:max(b)
    assert(self ~= nil and b ~= nil, "Cannot get maximum with nil vector")
    assert(type(self) == "table" and type(b) == "table", "Can only get maximum of Vector2 objects")
    return Vector2.new(math.max(self.x, b.x), math.max(self.y, b.y))
end

---@param a Vector2
---@return Vector2
function Vector2:clamp(min, max)
    assert(self ~= nil and min ~= nil and max ~= nil, "Cannot clamp with nil vectors")
    assert(type(self) == "table" and type(min) == "table" and type(max) == "table", "Can only clamp Vector2 objects")
    return Vector2.new(
        math.max(min.x, math.min(max.x, self.x)),
        math.max(min.y, math.min(max.y, self.y))
    )
end

---@param a Vector2
---@return Vector2
function Vector2:lerp(b, t)
    assert(self ~= nil and b ~= nil, "Cannot lerp with nil vectors")
    assert(type(self) == "table" and type(b) == "table", "Can only lerp Vector2 objects")
    assert(t >= 0 and t <= 1, "Lerp factor must be between 0 and 1")
    return Vector2.new(
        self.x + t * (b.x - self.x),
        self.y + t * (b.y - self.y)
    )
end

---@param a Vector2
---@return Vector2
function Vector2:unpack()
    assert(self ~= nil, "Cannot unpack nil vector")
    assert(type(self) == "table", "Can only unpack Vector2 object")
    return self.x, self.y
end

---@param a Vector2
---@return string
function Vector2:__tostring()
    assert(self ~= nil, "Cannot convert nil vector to string")
    assert(type(self) == "table", "Can only convert Vector2 object to string")
    return string.format("Vector2(%f, %f)", self.x, self.y)
end

function Vector2:normalized()
    local length = self:length()
    if length == 0 then
        return Vector2.new(0, 0)
    end
    return Vector2.new(self.x / length, self.y / length)
end

-- Add Vector2 to global game variable when loaded
_game = _game or {}
_game.Vector2 = Vector2

return Vector2 