local pos = require("src.base.pos")

---@class Decal
---@field pos pos The position of the decal
---@field kind string The kind of decal (from decals.kind)
---@field color table The color of the decal
---@field radius number The radius of the decal
---@field seed number Random seed for consistent appearance

-- Color definitions
local color_defs = {
    blood = {
        red = { 0.6, 0.9 },   -- Between 0.6 and 0.9
        green = { 0.0, 0.0 }, -- Always 0.0
        blue = { 0.0, 0.0 }   -- Always 0.0
    },
    mud = {
        red = { 0.4, 0.6 },   -- Between 0.4 and 0.6
        green = { 0.2, 0.3 }, -- Between 0.2 and 0.3
        blue = { 0.1, 0.15 }  -- Between 0.1 and 0.15
    },
    slime = {
        red = { 0.2, 0.3 },   -- Between 0.2 and 0.3
        green = { 0.6, 0.9 }, -- Between 0.6 and 0.9
        blue = { 0.2, 0.3 }   -- Between 0.2 and 0.3
    }
}

local decals = {
    active = {}, -- Array of active decals
    spread = 0.25 -- Safe spread distance for decals
}

---Create a single spot with given parameters
---@param data table The spot creation data
---@param data.pos pos The base position
---@param data.min_radius number Minimum radius for the spot (default: 1)
---@param data.max_radius number Maximum radius for the spot (default: 2)
---@param data.kind string The kind of decal
---@param data.color_def table Color definition with base and delta values for each channel
local function create_spot(data)
    local seed = data.pos.x * data.pos.y -- Use position as seed for consistency
    math.randomseed(seed)

    -- Convert spread to tile units
    local spread = decals.spread / DI.dungeon.tile_size

    -- Random positions within spread area
    local offset_x = math.random(-spread, spread)
    local offset_y = math.random(-spread, spread)

    -- Random size between min and max
    local radius = (data.min_radius or 1) + math.random() * ((data.max_radius or 2) - (data.min_radius or 1))

    -- Generate color from definition
    local c = data.color_def
    local color = {
        c.red[1] + math.random() * (c.red[2] - c.red[1]),
        c.green[1] + math.random() * (c.green[2] - c.green[1]),
        c.blue[1] + math.random() * (c.blue[2] - c.blue[1]),
        1
    }

    table.insert(decals.active, {
        pos = pos.new(data.pos.x + offset_x, data.pos.y + offset_y),
        kind = data.kind,
        color = color,
        radius = radius,
        seed = seed
    })
end

---Create a pool of spots with given parameters
---@param data table The pool creation data
---@param data.pos pos The position to spawn spots at
---@param data.count number Number of spots to create (default: 3)
---@param data.min_radius number Minimum radius for spots (default: 1)
---@param data.max_radius number Maximum radius for spots (default: 2)
---@param data.kind string The kind of decal
---@param data.color_def table Color definition with base and delta values for each channel
local function create_pool(data)
    for i = 1, (data.count or 3) do
        create_spot({
            pos = data.pos,
            min_radius = data.min_radius,
            max_radius = data.max_radius,
            kind = data.kind,
            color_def = data.color_def
        })
    end
end

---Create a slime spot
---@param pos pos The position to spawn slime at
local function create_slime(pos)
    create_spot({
        pos = pos,
        min_radius = 2,
        max_radius = 4,
        kind = "slime",
        color_def = color_defs.slime
    })
end

---Spawn a decal at the specified position
---@param kind string The kind of decal to spawn (from decals.kind)
---@param pos pos The position to spawn the decal at
function decals.spawn(kind, pos)
    if kind == "blood" then
        -- Small blood spots (3 spots, 1-2 pixels)
        create_pool({
            pos = pos,
            kind = "blood",
            color_def = color_defs.blood
        })
    elseif kind == "blood_pool" then
        -- Larger blood pool (5 spots, 2-5 pixels)
        create_pool({
            pos = pos,
            count = 5,
            min_radius = 2,
            max_radius = 5,
            kind = "blood",
            color_def = color_defs.blood
        })
    elseif kind == "slime" then
        -- Single greenish slime spot
        create_slime(pos)
    elseif kind == "mud" then
        -- Small mud spots (3 spots, 1-2 pixels)
        create_pool({
            pos = pos,
            kind = "mud",
            color_def = color_defs.mud
        })
    elseif kind == "mud_pool" then
        -- Larger mud pool (5 spots, 2-5 pixels)
        create_pool({
            pos = pos,
            count = 5,
            min_radius = 2,
            max_radius = 5,
            kind = "mud",
            color_def = color_defs.mud
        })
    end
end

function decals.draw()
    for _, decal in ipairs(decals.active) do
        local screen_pos = DI.dungeon.grid_to_screen(decal.pos)
        love.graphics.setColor(unpack(decal.color))
        love.graphics.circle("fill", screen_pos.x, screen_pos.y, decal.radius)
    end
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function decals.load(opts)
    opts = opts or { reset = true }
    if opts.reset then
        decals.active = {}
    end
end

return decals
