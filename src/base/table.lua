---Deep clone a table
---@param t table The table to clone
---@return table A new table with all the same values
local function clone(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = clone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local t = {
    clone = clone
}

return t 