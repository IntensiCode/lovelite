--- String utility extensions

--- Split a string by delimiter
--- @param str string The string to split
--- @param delimiter string The delimiter to split by
--- @return table Array of substrings
function string.split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)

    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end

    return result
end

--- Trim whitespace from both ends of a string
--- @param str string The string to trim
--- @return string The trimmed string
function string.trim(str)
    return str:gsub("^%s*(.-)%s*$", "%1")
end

--- Check if a string starts with a specific substring
--- @param str string The string to check
--- @param start string The substring to look for at the start
--- @return boolean True if the string starts with the substring
function string.starts_with(str, start)
    return str:sub(1, #start) == start
end

--- Check if a string ends with a specific substring
--- @param str string The string to check
--- @param ending string The substring to look for at the end
--- @return boolean True if the string ends with the substring
function string.ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

--- Check if a string contains a substring
--- @param str string The string to check
--- @param substring string The substring to look for
--- @return boolean True if the string contains the substring
function string.contains(str, substring)
    return str:find(substring, 1, true) ~= nil
end

--- Remove a prefix from a string if it exists
--- @param str string The string to modify
--- @param prefix string The prefix to remove
--- @return string The string with the prefix removed, or the original if no prefix
function string.remove_prefix(str, prefix)
    if string.starts_with(str, prefix) then
        return str:sub(#prefix + 1)
    end
    return str
end

--- Remove a suffix from a string if it exists
--- @param str string The string to modify
--- @param suffix string The suffix to remove
--- @return string The string with the suffix removed, or the original if no suffix
function string.remove_suffix(str, suffix)
    if string.ends_with(str, suffix) then
        return str:sub(1, #str - #suffix)
    end
    return str
end

--- Ensure a string has a specific prefix, adding it if not present
--- @param str string The string to check and modify
--- @param prefix string The prefix that should be present
--- @return string The string with the prefix guaranteed to be at the start
function string.ensure_prefix(str, prefix)
    if not string.starts_with(str, prefix) then
        return prefix .. str
    end
    return str
end

--- Ensure a string has a specific suffix, adding it if not present
--- @param str string The string to check and modify
--- @param suffix string The suffix that should be present
--- @return string The string with the suffix guaranteed to be at the end
function string.ensure_suffix(str, suffix)
    if not string.ends_with(str, suffix) then
        return str .. suffix
    end
    return str
end

return string
