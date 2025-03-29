--- List utilities for managing table-based lists
--- @module list
list = {}

--- Add an item to a list
--- @param tbl table The list to add to
--- @param item any The item to add
--- @param idx number? Optional index to insert at (defaults to end of list)
function list.add(tbl, item, idx)
    if idx then
        table.insert(tbl, idx, item)
    else
        table.insert(tbl, item)
    end
end

--- Remove an item from a list by index
--- @param tbl table The list to remove from
--- @param idx number The index to remove
--- @return any|nil The removed item or nil if index is invalid
function list.remove(tbl, idx)
    if idx > 0 and idx <= #tbl then
        return table.remove(tbl, idx)
    end
    return nil
end

--- Clear all items from a list
--- @param tbl table The list to clear
function list.clear(tbl)
    for i = #tbl, 1, -1 do
        table.remove(tbl, i)
    end
end

--- Get the size of a list
--- @param tbl table The list to measure
--- @return number The number of elements in the list
function list.size(tbl)
    return #tbl
end

--- Find the index of an item in a list
--- @param tbl table The list to search
--- @param item any The item to find
--- @return number|nil The index of the item or nil if not found
function list.find_index(tbl, item)
    for i, v in ipairs(tbl) do
        if v == item then
            return i
        end
    end
    return nil
end

--- Remove a specific item from a list
--- @param tbl table The list to remove from
--- @param item any The item to remove
--- @return boolean True if the item was found and removed
function list.remove_item(tbl, item)
    local idx = list.find_index(tbl, item)
    if idx then
        table.remove(tbl, idx)
        return true
    end
    return false
end

--- Check if a list contains an item
--- @param tbl table The list to check
--- @param item any The item to look for
--- @return boolean True if the item was found
function list.contains(tbl, item)
    return list.find_index(tbl, item) ~= nil
end

--- Iterate over each item in a list and call a function on it
--- @param tbl table The list to iterate over
--- @param func function The function to call for each item, receives just the item
function list.each(tbl, func)
    for _, v in ipairs(tbl) do
        func(v)
    end
end

--- Iterate over each item in a list and call a function on it with its index
--- @param tbl table The list to iterate over
--- @param func function The function to call for each item, receives (item, index)
function list.each_with_index(tbl, func)
    for i, v in ipairs(tbl) do
        func(v, i)
    end
end

--- Create a new list by applying a function to each item in the original list
--- @param tbl table The source list
--- @param func function The mapping function that transforms items, receives (item, index)
--- @return table A new list containing the mapped values
function list.map(tbl, func)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = func(v, i)
    end
    return result
end

return list 