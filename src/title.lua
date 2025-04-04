---@diagnostic disable: duplicate-set-field
local title = {}

local PADDING = 8

local FLAME_POSITIONS = {
    { x = 50, y = 90 }, -- Left flame
    { x = 270, y = 90 }, -- Right flame
}

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

function title.switch_to_game()
    if not DI.fade.transitioning then
        DI.fade.on_fade_done = function()
            DI.screen.switch_to("game")
        end
        DI.fade.reset("fade_out", 0.2)
    end
end

function title.fade_and_quit()
    if DI.fade.on_fade_done then
        return
    end
    DI.fade.on_fade_done = function()
        love.event.quit()
    end
    DI.fade.reset("fade_out", 0.2)
end

function title.attach()
    DI.keys.add_shortcut("space", {
        callback = function()
            title.switch_to_game()
        end,
        description = "Start game",
        scope = "title",
    })
    DI.keys.add_shortcut("escape", {
        callback = function()
            title.fade_and_quit()
        end,
        description = "Exit game",
        scope = "title",
    })
end

---Unregister title-specific keyboard shortcuts
function title.detach()
    DI.keys.remove_shortcuts_by_scope("title")
end

-- Load assets
function title.load()
    -- Initialize camera
    DI.camera.load({ reset = true })

    -- Load title screen images
    title.background = DI.lg.newImage("assets/title_background.png")
    title.logo = DI.lg.newImage("assets/title_logo.png")
    title.flame = DI.lg.newImage("assets/title_flame.png")

    -- Create shader
    title.fire_shader = DI.lg.newShader(FIRE_SHADER)

    -- Initialize time for flame animation
    title.time = 0

    -- Initialize blink timer
    title.blink_timer = 0
    title.blink_visible = true

    -- Calculate logo position
    title.logo_x = (DI.camera.width - title.logo:getWidth()) / 2
    title.logo_y = 20

    -- Start with fade in
    DI.fade.on_fade_done = nil -- No callback needed for initial fade
    DI.fade.reset("fade_in", 0.2)
end

function title.update(dt)
    -- Update fade
    DI.fade.update(dt)

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
end

function title.draw()
    -- Begin camera transform
    DI.camera.beginDraw()

    -- Draw background
    DI.lg.draw(title.background, 0, 0)

    -- Draw logo
    DI.lg.setColor(1, 1, 1, 1)
    DI.lg.draw(title.logo, title.logo_x, title.logo_y)

    -- Draw flames with shader and additive blending
    DI.lg.setBlendMode("add")
    DI.lg.setShader(title.fire_shader)

    for _, pos in ipairs(FLAME_POSITIONS) do
        -- Calculate base position (bottom-center aligned)
        local flame_x = pos.x - title.flame:getWidth() / 2
        local flame_y = pos.y - title.flame:getHeight()

        -- Add subtle vertical scaling
        local scale_y = 1 + math.sin(title.time * 3) * 0.1 -- 10% scale variation

        -- Draw with scaling from bottom point
        DI.lg.push()
        DI.lg.translate(pos.x, pos.y) -- Move to bottom center
        DI.lg.scale(1, scale_y) -- Scale vertically
        DI.lg.translate(-title.flame:getWidth() / 2, -title.flame:getHeight()) -- Offset for bottom-center alignment
        DI.lg.draw(title.flame, 0, 0)
        DI.lg.pop()
    end

    -- Reset graphics state
    DI.lg.setShader()
    DI.lg.setBlendMode("alpha")

    -- Draw "Press SPACE to start" text (only when visible)
    if title.blink_visible then
        local text = "Press SPACE to start"
        DI.font.draw_text(
            text,
            DI.camera.width / 2,
            DI.camera.height - PADDING,
            DI.font.anchor.bottom_center
        )
    end

    -- Draw fade overlay last
    DI.fade.draw(DI.camera.width, DI.camera.height)

    -- End camera transform
    DI.camera.endDraw()
end

function title.resize(w, h)
    DI.camera.resize(w, h)
end

return title
