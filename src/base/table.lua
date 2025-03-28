---Table utility extensions

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