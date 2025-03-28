local t = {}

---Deep clone a table
---@param table table The table to clone
---@return table A new table with all the same values
function t.clone(table)
    local copy = {}
    for k, v in pairs(table) do
        if type(v) == "table" then
            copy[k] = t.clone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Print keys, sorted by name
function t.print_keys(table, indent)
    indent = indent or ""
    local keys = {}
    for k in pairs(table) do
        _G.table.insert(keys, k)
    end
    _G.table.sort(keys)
    for _, k in ipairs(keys) do
        print(indent .. k)
    end
end

-- Deep dump a table
---@param name string The name of the table to dump
---@param table table The table to dump
---@param indent string? The indent string
function t.dump(name, table, indent)
    indent = indent or ""
    print(indent .. name .. ":")
    indent = indent .. "  "

    -- Collect and sort keys
    local keys = {}
    for k in pairs(table) do
        _G.table.insert(keys, k)
    end
    _G.table.sort(keys)

    -- Split into tables and non-tables
    local table_keys = {}
    local non_table_keys = {}
    for _, k in ipairs(keys) do
        if type(table[k]) == "table" then
            _G.table.insert(table_keys, k)
        else
            _G.table.insert(non_table_keys, k)
        end
    end

    -- Process non-tables first
    for _, k in ipairs(non_table_keys) do
        print(indent .. k .. ": " .. tostring(table[k]))
    end

    -- Then process tables
    for _, k in ipairs(table_keys) do
        t.dump(k, table[k], indent)
    end
end

return t 