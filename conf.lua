function love.conf(t)
    t.identity = "love-test"        -- The name of the save directory
    t.version = "11.4"              -- The LÖVE version this game was made for
    t.console = true               -- Enable the console (useful for debugging)
    
    t.window.title = "My LÖVE Game"
    t.window.icon = nil            -- Filepath to an image to use as the window's icon
    t.window.width = 800
    t.window.height = 600
    t.window.borderless = false    -- Remove all border visuals from the window
    t.window.resizable = true      -- Let the window be user-resizable
    t.window.minwidth = 320          -- Minimum window width if the window is resizable
    t.window.minheight = 240         -- Minimum window height if the window is resizable
    t.window.fullscreen = false    -- Enable fullscreen
    t.window.fullscreentype = "desktop" -- Choose between "desktop" fullscreen or "exclusive" fullscreen mode
    t.window.vsync = 1             -- Vertical sync mode (0-1)
    t.window.msaa = 0              -- The number of samples to use with multi-sampled antialiasing
    t.window.depth = nil           -- The number of bits per sample in the depth buffer
    t.window.stencil = nil         -- The number of bits per sample in the stencil buffer
    t.window.display = 1           -- Index of the monitor to show the window in
    t.window.highdpi = false       -- Enable high-dpi mode for the window on a Retina display
    t.window.usedpiscale = true    -- Enable automatic DPI scaling
    t.window.x = 1               -- The x-coordinate of the window's position in the specified display
    t.window.y = 1               -- The y-coordinate of the window's position in the specified display
end 