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
    log.assert(a ~= nil and b ~= nil, "Cannot add nil vectors")
    log.assert(type(a) == "table" and type(b) == "table", "Can only add pos objects")
    return pos.new(a.x + b.x, a.y + b.y)
end

---@param a pos
---@param b pos
---@return pos
function pos.__sub(a, b)
    log.assert(a ~= nil and b ~= nil, "Cannot subtract nil vectors")
    log.assert(type(a) == "table" and type(b) == "table", "Can only subtract pos objects")
    return pos.new(a.x - b.x, a.y - b.y)
end

---@param a pos
---@param b number|pos
---@return pos
function pos.__mul(a, b)
    log.assert(a ~= nil, "Cannot multiply nil vector")
    log.assert(type(a) == "table", "Can only multiply pos objects")

    if type(b) == "number" then
        return pos.new(a.x * b, a.y * b)
    end

    log.assert(b ~= nil, "Cannot multiply by nil")
    log.assert(type(b) == "table", "Can only multiply by pos or number")
    return pos.new(a.x * b.x, a.y * b.y) -- Element-wise multiplication
end

---@param a pos
---@param b number|pos
---@return pos
function pos.__div(a, b)
    log.assert(a ~= nil, "Cannot divide nil vector")
    log.assert(type(a) == "table", "Can only divide pos objects")

    if type(b) == "number" then
        log.assert(b ~= 0, "Cannot divide by zero")
        return pos.new(a.x / b, a.y / b)
    end

    log.assert(b ~= nil, "Cannot divide by nil")
    log.assert(type(b) == "table", "Can only divide by pos or number")
    log.assert(b.x ~= 0 and b.y ~= 0, "Cannot divide by zero")
    return pos.new(a.x / b.x, a.y / b.y) -- Element-wise division
end

---@param a pos
---@return number
function pos:length()
    log.assert(self ~= nil, "Cannot get length of nil vector")
    log.assert(type(self) == "table", "Can only get length of pos object")
    return math.sqrt(self.x * self.x + self.y * self.y)
end

---@param a pos
---@return pos
function pos:normalize()
    log.assert(self ~= nil, "Cannot normalize nil vector")
    log.assert(type(self) == "table", "Can only normalize pos object")
    local len = self:length()
    log.assert(len ~= 0, "Cannot normalize zero vector")
    return pos.new(self.x / len, self.y / len)
end

---@param a pos
---@param b pos
---@return number
function pos:dot(b)
    log.assert(self ~= nil and b ~= nil, "Cannot dot product with nil vector")
    log.assert(type(self) == "table" and type(b) == "table", "Can only dot product pos objects")
    return self.x * b.x + self.y * b.y
end

---@param a pos
---@param b pos
---@return number
function pos:distance(b)
    log.assert(self ~= nil and b ~= nil, "Cannot get distance to nil vector")
    log.assert(type(self) == "table" and type(b) == "table", "Can only get distance between pos objects")
    return (b - self):length()
end

---@param a pos
---@return pos
function pos:rotate(angle)
    log.assert(self ~= nil, "Cannot rotate nil vector")
    log.assert(type(self) == "table", "Can only rotate pos object")
    local cos_angle = math.cos(angle)
    local sin_angle = math.sin(angle)
    return pos.new(
        self.x * cos_angle - self.y * sin_angle,
        self.x * sin_angle + self.y * cos_angle
    )
end

---@param a pos
---@return pos
function pos:round()
    log.assert(self ~= nil, "Cannot round nil vector")
    log.assert(type(self) == "table", "Can only round pos object")
    return pos.new(math.round(self.x), math.round(self.y))
end

---@param a pos
---@return pos
function pos:floor()
    log.assert(self ~= nil, "Cannot floor nil vector")
    log.assert(type(self) == "table", "Can only floor pos object")
    return pos.new(math.floor(self.x), math.floor(self.y))
end

---@param a pos
---@return pos
function pos:ceil()
    log.assert(self ~= nil, "Cannot ceil nil vector")
    log.assert(type(self) == "table", "Can only ceil pos object")
    return pos.new(math.ceil(self.x), math.ceil(self.y))
end

---@param a pos
---@return pos
function pos:abs()
    log.assert(self ~= nil, "Cannot get absolute value of nil vector")
    log.assert(type(self) == "table", "Can only get absolute value of pos object")
    return pos.new(math.abs(self.x), math.abs(self.y))
end

---@param a pos
---@return pos
function pos:min(b)
    log.assert(self ~= nil and b ~= nil, "Cannot get minimum with nil vector")
    log.assert(type(self) == "table" and type(b) == "table", "Can only get minimum of pos objects")
    return pos.new(math.min(self.x, b.x), math.min(self.y, b.y))
end

---@param a pos
---@return pos
function pos:max(b)
    log.assert(self ~= nil and b ~= nil, "Cannot get maximum with nil vector")
    log.assert(type(self) == "table" and type(b) == "table", "Can only get maximum of pos objects")
    return pos.new(math.max(self.x, b.x), math.max(self.y, b.y))
end

---@param a pos
---@return pos
function pos:clamp(min, max)
    log.assert(self ~= nil and min ~= nil and max ~= nil, "Cannot clamp with nil vectors")
    log.assert(type(self) == "table" and type(min) == "table" and type(max) == "table", "Can only clamp pos objects")
    return pos.new(
        math.clamp(self.x, min.x, max.x),
        math.clamp(self.y, min.y, max.y)
    )
end

---@param a pos
---@return pos
function pos:lerp(b, t)
    log.assert(self ~= nil and b ~= nil, "Cannot lerp with nil vectors")
    log.assert(type(self) == "table" and type(b) == "table", "Can only lerp pos objects")
    log.assert(t >= 0 and t <= 1, "Lerp factor must be between 0 and 1")

    return self + (b - self) * t
end

---@param a pos
---@return pos
function pos:unpack()
    log.assert(self ~= nil, "Cannot unpack nil vector")
    log.assert(type(self) == "table", "Can only unpack pos object")
    return self.x, self.y
end

---@param a pos
---@return string
function pos:__tostring()
    log.assert(self ~= nil, "Cannot convert nil vector to string")
    log.assert(type(self) == "table", "Can only convert pos object to string")
    return string.format("pos(%.3f, %.3f)", self.x, self.y)
end

function pos:normalized()
    local length = self:length()
    if length == 0 then
        return pos.new(0, 0)
    end
    return pos.new(self.x / length, self.y / length)
end

return pos
