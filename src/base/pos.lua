---@class pos
---@field x number
---@field y number
local pos = {
    x = 0,
    y = 0
}
pos.__index = pos

---@param x number
---@param y number
---@return pos
function pos.new(x, y)
    local v = setmetatable({}, pos)
    v.x = x
    v.y = y
    return v
end

---@param a pos
---@param b pos
---@return pos
function pos.__add(a, b)
    assert(a ~= nil and b ~= nil, "Cannot add nil vectors")
    assert(type(a) == "table" and type(b) == "table", "Can only add pos objects")
    return pos.new(a.x + b.x, a.y + b.y)
end

---@param a pos
---@param b pos
---@return pos
function pos.__sub(a, b)
    assert(a ~= nil and b ~= nil, "Cannot subtract nil vectors")
    assert(type(a) == "table" and type(b) == "table", "Can only subtract pos objects")
    return pos.new(a.x - b.x, a.y - b.y)
end

---@param a pos
---@param b number|pos
---@return pos
function pos.__mul(a, b)
    assert(a ~= nil, "Cannot multiply nil vector")
    assert(type(a) == "table", "Can only multiply pos objects")
    if type(b) == "number" then
        return pos.new(a.x * b, a.y * b)
    else
        assert(b ~= nil, "Cannot multiply by nil")
        assert(type(b) == "table", "Can only multiply by pos or number")
        return pos.new(a.x * b.x, a.y * b.y)
    end
end

---@param a pos
---@param b number|pos
---@return pos
function pos.__div(a, b)
    assert(a ~= nil, "Cannot divide nil vector")
    assert(type(a) == "table", "Can only divide pos objects")
    if type(b) == "number" then
        assert(b ~= 0, "Cannot divide by zero")
        return pos.new(a.x / b, a.y / b)
    else
        assert(b ~= nil, "Cannot divide by nil")
        assert(type(b) == "table", "Can only divide by pos or number")
        assert(b.x ~= 0 and b.y ~= 0, "Cannot divide by zero")
        return pos.new(a.x / b.x, a.y / b.y)
    end
end

---@param a pos
---@return number
function pos:length()
    assert(self ~= nil, "Cannot get length of nil vector")
    assert(type(self) == "table", "Can only get length of pos object")
    return math.sqrt(self.x * self.x + self.y * self.y)
end

---@param a pos
---@return pos
function pos:normalize()
    assert(self ~= nil, "Cannot normalize nil vector")
    assert(type(self) == "table", "Can only normalize pos object")
    local len = self:length()
    assert(len ~= 0, "Cannot normalize zero vector")
    return pos.new(self.x / len, self.y / len)
end

---@param a pos
---@param b pos
---@return number
function pos:dot(b)
    assert(self ~= nil and b ~= nil, "Cannot dot product with nil vector")
    assert(type(self) == "table" and type(b) == "table", "Can only dot product pos objects")
    return self.x * b.x + self.y * b.y
end

---@param a pos
---@param b pos
---@return number
function pos:distance(b)
    assert(self ~= nil and b ~= nil, "Cannot get distance to nil vector")
    assert(type(self) == "table" and type(b) == "table", "Can only get distance between pos objects")
    return (b - self):length()
end

---@param a pos
---@return pos
function pos:rotate(angle)
    assert(self ~= nil, "Cannot rotate nil vector")
    assert(type(self) == "table", "Can only rotate pos object")
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    return pos.new(
        self.x * cos - self.y * sin,
        self.x * sin + self.y * cos
    )
end

---@param a pos
---@return pos
function pos:round()
    assert(self ~= nil, "Cannot round nil vector")
    assert(type(self) == "table", "Can only round pos object")
    return pos.new(math.floor(self.x + 0.5), math.floor(self.y + 0.5))
end

---@param a pos
---@return pos
function pos:floor()
    assert(self ~= nil, "Cannot floor nil vector")
    assert(type(self) == "table", "Can only floor pos object")
    return pos.new(math.floor(self.x), math.floor(self.y))
end

---@param a pos
---@return pos
function pos:ceil()
    assert(self ~= nil, "Cannot ceil nil vector")
    assert(type(self) == "table", "Can only ceil pos object")
    return pos.new(math.ceil(self.x), math.ceil(self.y))
end

---@param a pos
---@return pos
function pos:abs()
    assert(self ~= nil, "Cannot get absolute value of nil vector")
    assert(type(self) == "table", "Can only get absolute value of pos object")
    return pos.new(math.abs(self.x), math.abs(self.y))
end

---@param a pos
---@return pos
function pos:min(b)
    assert(self ~= nil and b ~= nil, "Cannot get minimum with nil vector")
    assert(type(self) == "table" and type(b) == "table", "Can only get minimum of pos objects")
    return pos.new(math.min(self.x, b.x), math.min(self.y, b.y))
end

---@param a pos
---@return pos
function pos:max(b)
    assert(self ~= nil and b ~= nil, "Cannot get maximum with nil vector")
    assert(type(self) == "table" and type(b) == "table", "Can only get maximum of pos objects")
    return pos.new(math.max(self.x, b.x), math.max(self.y, b.y))
end

---@param a pos
---@return pos
function pos:clamp(min, max)
    assert(self ~= nil and min ~= nil and max ~= nil, "Cannot clamp with nil vectors")
    assert(type(self) == "table" and type(min) == "table" and type(max) == "table", "Can only clamp pos objects")
    return pos.new(
        math.max(min.x, math.min(max.x, self.x)),
        math.max(min.y, math.min(max.y, self.y))
    )
end

---@param a pos
---@return pos
function pos:lerp(b, t)
    assert(self ~= nil and b ~= nil, "Cannot lerp with nil vectors")
    assert(type(self) == "table" and type(b) == "table", "Can only lerp pos objects")
    assert(t >= 0 and t <= 1, "Lerp factor must be between 0 and 1")
    return pos.new(
        self.x + t * (b.x - self.x),
        self.y + t * (b.y - self.y)
    )
end

---@param a pos
---@return pos
function pos:unpack()
    assert(self ~= nil, "Cannot unpack nil vector")
    assert(type(self) == "table", "Can only unpack pos object")
    return self.x, self.y
end

---@param a pos
---@return string
function pos:__tostring()
    assert(self ~= nil, "Cannot convert nil vector to string")
    assert(type(self) == "table", "Can only convert pos object to string")
    return string.format("pos(%f, %f)", self.x, self.y)
end

function pos:normalized()
    local length = self:length()
    if length == 0 then
        return pos.new(0, 0)
    end
    return pos.new(self.x / length, self.y / length)
end

-- Add pos to global game variable when loaded
_game = _game or {}
_game.pos = pos

return pos 