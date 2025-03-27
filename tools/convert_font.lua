-- Convert DST font format to BMFont format
local function read_dst_file(path)
    local widths = {}
    local f = io.open(path, "rb")
    if not f then return nil end
    
    local content = f:read("*all")
    f:close()
    
    -- Parse space-separated hex values
    for width in content:gmatch("%x%x") do
        table.insert(widths, tonumber(width, 16))
    end
    
    return widths
end

local function write_bmfont_file(path, widths, font_name)
    local f = io.open(path, "w")
    if not f then return false end
    
    -- Write BMFont file header with 1 pixel horizontal spacing
    f:write(string.format('info face="%s" size=8 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,0 outline=0\n', font_name))
    f:write('common lineHeight=8 base=8 scaleW=128 scaleH=64 pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0\n')
    f:write(string.format('page id=0 file="%s.png"\n', font_name))
    
    -- Count how many characters we have
    local count = #widths
    f:write(string.format('chars count=%d\n', count))
    
    -- Write character info
    -- Characters are arranged in a 16x8 grid, each 8x8 pixels
    for i = 0, count-1 do
        local x = (i % 16) * 8
        local y = math.floor(i / 16) * 8
        local width = widths[i+1] or 8
        -- Add 1 pixel to xadvance for spacing
        local xadvance = width + 1
        -- char id=32 x=0 y=0 width=8 height=8 xoffset=0 yoffset=0 xadvance=4 page=0 chnl=15
        f:write(string.format('char id=%d x=%d y=%d width=%d height=8 xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15\n',
            i+32, x, y, width, xadvance))
    end
    
    f:close()
    return true
end

-- Convert all fonts
local fonts = {
    "font_tiny",
    "font_mini",
    "font_menu",
    "font_fancy"
}

for _, font_name in ipairs(fonts) do
    print(string.format("Converting %s...", font_name))
    local widths = read_dst_file(string.format("assets/fonts/%s.dst", font_name))
    if widths then
        local success = write_bmfont_file(
            string.format("assets/fonts/%s.fnt", font_name),
            widths,
            font_name
        )
        if success then
            print(string.format("Successfully converted %s", font_name))
        else
            print(string.format("Failed to write BMFont file for %s", font_name))
        end
    else
        print(string.format("Failed to read DST file for %s", font_name))
    end
end 