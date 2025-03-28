---@class PositionProvider
---@field get_positions fun():table[] Function that returns array of {id:string, pos:pos}

local positions = {
    providers = {}
}

---Add a position provider
---@param get_positions fun():table[] Function that returns array of {id:string, pos:pos}
function positions.add_provider(get_positions)
    table.insert(positions.providers, {
        get_positions = get_positions
    })
end

---Get all current positions except for specified ID
---@param exclude_id? string Optional ID to exclude from results
---@return table[] positions Array of {id:string, pos:pos}
function positions.get_all_except(exclude_id)
    local all_positions = {}

    for _, provider in ipairs(positions.providers) do
        local positions = provider.get_positions()
        for _, pos_data in ipairs(positions) do
            if pos_data.id ~= exclude_id then
                table.insert(all_positions, pos_data)
            end
        end
    end

    return all_positions
end

return positions
