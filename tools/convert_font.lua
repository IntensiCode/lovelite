-- Convert DST font format to BMFont format
local function read_dst_file(path)
    local widths = {}
    local f = io.open(path, "rb")
    if not f then return nil end
    
    local content = f:read("*all")
    f:close()
    
    -- Parse space-separated hex values
    local valid_count = 0
    for width in content:gmatch("%x%x") do
        local w = tonumber(width, 16)
        if w > 0 then
            valid_count = valid_count + 1
        end
        table.insert(widths, w)
    end
    
    return widths, valid_count
end

-- Convert a font to BMFont format
local function convert(base_name, char_width, char_height, padding)
    padding = padding or 0
    print(string.format("Converting %s...", base_name))
    
    -- Calculate image dimensions based on 16x8 character grid
    local image_width = 16 * char_width
    local image_height = 8 * char_height
    
    -- Read character widths
    local widths, valid_count = read_dst_file(string.format("assets/fonts/%s.dst", base_name))
    if not widths then
        print(string.format("Failed to read DST file for %s", base_name))
        return false
    end
    
    print(string.format("Found %d valid characters", valid_count))
    
    -- Write BMFont file
    local f = io.open(string.format("assets/fonts/%s.fnt", base_name), "w")
    if not f then
        print(string.format("Failed to create FNT file for %s", base_name))
        return false
    end
    
    -- Write BMFont file header
    f:write(string.format('info face="%s" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,0 outline=0\n', 
        base_name, char_height))
    f:write(string.format('common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0\n',
        char_height, char_height, image_width, image_height))
    f:write(string.format('page id=0 file="%s.png"\n', base_name))
    
    -- Write only valid characters
    f:write(string.format('chars count=%d\n', valid_count))
    
    -- Write character info only for valid characters
    for i = 0, #widths-1 do
        if widths[i+1] and widths[i+1] > 0 then
            local x = (i % 16) * char_width
            local y = math.floor(i / 16) * char_height
            local width = widths[i+1]
            -- Add padding to xadvance
            local xadvance = width + padding
            f:write(string.format('char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15\n',
                i+32, x, y, width, char_height, xadvance))
        end
    end
    
    f:close()
    print(string.format("Successfully converted %s", base_name))
    return true
end

convert("font_fancy", 12, 10, 1)
convert("font_menu", 32, 32, 1)
convert("font_mini", 8, 8, 1)
convert("font_tiny", 8, 8, 1)