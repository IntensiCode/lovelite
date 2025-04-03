---Table utility extensions
---GLOBAL DEFINITIONS - REQUIRE WITHOUT ASSIGNING TO A VARIABLE

function table.deepcopy(tbl)
    return table.clone(tbl)
end

---Deep clone a table
---@param tbl table The table to clone
---@return table A new table with all the same values
function table.clone(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = table.clone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

---Print keys, sorted by name
---@param tbl table The table to print keys for
---@param indent string? Optional indentation string
function table.print_keys(tbl, indent)
    indent = indent or ""
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    for _, k in ipairs(keys) do
        log.debug(indent .. k)
    end
end

---Deep dump a table
---@param name string The name of the table to dump
---@param tbl table The table to dump
---@param indent string? The indent string
function table.print_deep(name, tbl, indent)
    indent = indent or ""
    log.debug(indent .. name .. ":")
    indent = indent .. "  "

    -- Collect and sort keys
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)

    -- Split into tables and non-tables
    local table_keys = {}
    local non_table_keys = {}
    for _, k in ipairs(keys) do
        if type(tbl[k]) == "table" then
            table.insert(table_keys, k)
        else
            table.insert(non_table_keys, k)
        end
    end

    -- Process non-tables first
    for _, k in ipairs(non_table_keys) do
        log.debug(indent .. k .. ": " .. tostring(tbl[k]))
    end

    -- Then process tables
    for _, k in ipairs(table_keys) do
        table.print_deep(k, tbl[k], indent)
    end
end

---Transform each element of a table using a function
---@param tbl table The input table
---@param f fun(any):any The transformation function
---@return table The new table with transformed elements
function table.map(tbl, f)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = f(v)
    end
    return result
end

--- Count the number of key-value pairs in a table
---@param t table The table to count
---@return number The number of entries in the table
function table.count(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---Transform a list into a key-value mapping using a transform function
---@param tbl table The input table (list)
---@param f fun(value:any):(any,any) Function that returns key,value for each element
---@return table<any,any> The resulting key-value mapping
function table.associate(tbl, f)
    local result = {}
    for _, v in ipairs(tbl) do
        local key, value = f(v)
        result[key] = value
    end
    return result
end

---Filter a table based on a predicate function
---@param tbl table The input table
---@param predicate fun(value:any):boolean Function that returns true for elements to keep
---@return table A new table containing only elements for which predicate returns true
function table.filter(tbl, predicate)
    local result = {}
    for i, v in ipairs(tbl) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

---Filters elements into two separate tables based on a predicate
---@param tbl table The input table
---@param predicate fun(value:any):boolean Function that determines which table an element goes into
---@param filtered table Table to store elements for which predicate returns true
---@param rejected table Table to store elements for which predicate returns false
function table.filter_and_reject(tbl, predicate, filtered, rejected)
    for _, v in ipairs(tbl) do
        if predicate(v) then
            table.insert(filtered, v)
        else
            table.insert(rejected, v)
        end
    end
end

---Compare two tables for equality by checking all key/value pairs
---@param tbl1 table First table to compare
---@param tbl2 table Second table to compare
---@return boolean True if tables have identical key/value pairs
function table.equal(tbl1, tbl2)
    -- Check first direction: all values in tbl1 match tbl2
    for k, v in pairs(tbl1) do
        if tbl2[k] ~= v then
            return false
        end
    end

    -- Check second direction: all values in tbl2 match tbl1
    for k, v in pairs(tbl2) do
        if tbl1[k] ~= v then
            return false
        end
    end

    return true
end

---Search for a simple (non-table) value in a table
---@param tbl table The table to search
---@param value any The value to find
---@return boolean True if the value exists in the table
function table.contains_value(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

---Search for a table with matching structure in a table
---@param tbl table The table to search
---@param value table The table structure to find
---@return boolean True if a matching table exists
function table.contains_table(tbl, value)
    for _, v in pairs(tbl) do
        if type(v) == "table" and table.equal(v, value) then
            return true
        end
    end
    return false
end

---Check if a value exists in a table
---@param tbl table The table to search
---@param value any The value to find
---@param deep_compare boolean? Whether to perform a deep comparison for table values (defaults to false)
---@return boolean True if the value exists in the table
function table.contains(tbl, value, deep_compare)
    if deep_compare and type(value) == "table" then
        return table.contains_table(tbl, value)
    else
        return table.contains_value(tbl, value)
    end
end

---Check if any element in a table satisfies a predicate function
---@param tbl table The table to check
---@param predicate fun(value:any, key:any):boolean Function that returns true for satisfying elements
---@return boolean True if any element satisfies the predicate
function table.any(tbl, predicate)
    for k, v in pairs(tbl) do
        if predicate(v, k) then
            return true
        end
    end
    return false
end

---Check if all elements in a table satisfy a predicate function
---@param tbl table The table to check
---@param predicate fun(value:any, key:any):boolean Function that returns true for satisfying elements
---@return boolean True if all elements satisfy the predicate
function table.all(tbl, predicate)
    for k, v in pairs(tbl) do
        if not predicate(v, k) then
            return false
        end
    end
    return true
end

---Recursively concatenate all stringifiable values within a table, traversing nested tables.
---Keys are sorted before concatenation for deterministic output (numbers first, then strings).
---@param tbl table The table to concatenate
---@param sep string? The separator string (defaults to "")
---@return string The concatenated string
function table.concat_deep(tbl, sep)
    sep = sep or ""
    local result = {}
    local keys = {}

    -- Collect all keys from the table
    for k in pairs(tbl) do
        table.insert(keys, k)
    end

    -- Sort keys for deterministic output: numeric keys first, then string keys
    table.sort(keys, function(a, b)
        local type_a = type(a)
        local type_b = type(b)
        if type_a == "number" and type_b == "number" then
            return a < b
        elseif type_a == "string" and type_b == "string" then
            return a < b
        elseif type_a == "number" and type_b == "string" then
            return true -- Numbers come before strings
        elseif type_a == "string" and type_b == "number" then
            return false -- Strings come after numbers
        else
            -- Fallback for other types (though less common as keys)
            return tostring(a) < tostring(b)
        end
    end)

    -- Process values in the sorted key order
    for _, k in ipairs(keys) do
        local v = tbl[k]
        if type(v) == "table" then
            -- Recursively concatenate nested tables
            table.insert(result, table.concat_deep(v, sep))
        else
            -- Convert non-table values to string and add them
            table.insert(result, tostring(v))
        end
    end

    -- Concatenate the final list of strings
    return table.concat(result, sep)
end
