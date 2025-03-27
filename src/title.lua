local title = {}
local screen = require("src.base.screen")
local camera = require("src.camera")
local font = require("src.base.font")
local fade = require("src.base.fade")

-- Constants
local PADDING = 8

-- Flame positions (adjust these to match your background image)
local FLAME_POSITIONS = {
    { x = 50,  y = 90 }, -- Left flame
    { x = 270, y = 90 } -- Right flame
}

-- Fire shader code
local FIRE_SHADER = [[
    extern float time;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        // Create fire-like distortion
        float distortion = sin(texture_coords.y * 10.0 + time * 5.0) * 0.02;
        distortion += cos(texture_coords.y * 8.0 - time * 3.0) * 0.01;

        // Sample with distortion
        vec4 pixel = Texel(tex, vec2(texture_coords.x + distortion, texture_coords.y));

        // Add some color variation based on y position
        float intensity = 1.0 + sin(time * 4.0 + texture_coords.y * 5.0) * 0.1;
        vec4 final_color = pixel * color;
        final_color.r *= intensity;
        final_color.g *= intensity * 0.8;

        return final_color;
    }
]]

-- Load assets
function title.load()
    -- Load title screen images
    title.background = love.graphics.newImage("assets/title_background.png")
    title.logo = love.graphics.newImage("assets/title_logo.png")
    title.flame = love.graphics.newImage("assets/title_flame.png")

    -- Create shader
    title.fire_shader = love.graphics.newShader(FIRE_SHADER)

    -- Initialize camera
    camera.load()

    -- Initialize time for flame animation
    title.time = 0

    -- Initialize blink timer
    title.blink_timer = 0
    title.blink_visible = true

    -- Calculate logo position
    title.logo_x = (camera.width - title.logo:getWidth()) / 2
    title.logo_y = 20

    -- Start with fade in
    fade.on_fade_done = nil  -- No callback needed for initial fade
    fade.reset("fade_in", 0.2)
end

function title.update(dt)
    -- Update fade
    fade.update(dt)

    -- Update time for flame animation
    title.time = title.time + dt

    -- Update shader uniforms
    title.fire_shader:send("time", title.time)

    -- Update blink timer
    title.blink_timer = title.blink_timer + dt
    if title.blink_visible and title.blink_timer >= 0.8 then
        title.blink_visible = false
        title.blink_timer = 0
    elseif not title.blink_visible and title.blink_timer >= 0.2 then
        title.blink_visible = true
        title.blink_timer = 0
    end

    -- Check for space key press to start game
    if love.keyboard.isDown("space") and not fade.transitioning then
        fade.on_fade_done = function()
            screen.switch_to("game")
        end
        fade.reset("fade_out", 0.2)
    end
end

function title.draw()
    -- Begin camera transform
    camera.beginDraw()

    -- Draw background
    love.graphics.draw(title.background, 0, 0)

    -- Draw logo
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(title.logo, title.logo_x, title.logo_y)

    -- Draw flames with shader and additive blending
    love.graphics.setBlendMode("add")
    love.graphics.setShader(title.fire_shader)

    for _, pos in ipairs(FLAME_POSITIONS) do
        -- Calculate base position (bottom-center aligned)
        local flame_x = pos.x - title.flame:getWidth() / 2
        local flame_y = pos.y - title.flame:getHeight()

        -- Add subtle vertical scaling
        local scale_y = 1 + math.sin(title.time * 3) * 0.1 -- 10% scale variation

        -- Draw with scaling from bottom point
        love.graphics.push()
        love.graphics.translate(pos.x, pos.y)                                          -- Move to bottom center
        love.graphics.scale(1, scale_y)                                                -- Scale vertically
        love.graphics.translate(-title.flame:getWidth() / 2, -title.flame:getHeight()) -- Offset for bottom-center alignment
        love.graphics.draw(title.flame, 0, 0)
        love.graphics.pop()
    end

    -- Reset graphics state
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")

    -- Draw "Press SPACE to start" text (only when visible)
    if title.blink_visible then
        local text = "Press SPACE to start"
        font.draw_text(text, camera.width/2, camera.height - PADDING, font.anchor.bottom_center)
    end

    -- Draw fade overlay last
    fade.draw(camera.width, camera.height)

    -- End camera transform
    camera.endDraw()
end

function title.keypressed(key)
    -- Nop for now
end

function title.resize(w, h)
    camera.resize(w, h)
end

return title
