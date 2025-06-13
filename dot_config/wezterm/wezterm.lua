local wezterm = require 'wezterm'

local config = {
    adjust_window_size_when_changing_font_size = false,
    enable_tab_bar = false,
    font_size = 14.0,
    font = wezterm.font('JetBrains Mono'),
    macos_window_background_blur = 30,

    -- window_background_image = '/Users/omerhamerman/Downloads/3840x1080-Wallpaper-041.jpg',
    -- window_background_image_hsb = {
    -- 	brightness = 0.01,
    -- 	hue = 1.0,
    -- 	saturation = 0.5,
    -- },
    window_background_opacity = 0.92,
    -- window_background_opacity = 1.0,
    -- window_background_opacity = 0.78,
    -- window_background_opacity = 0.20,
    -- window_decorations = 'RESIZE',
    keys = {{
        key = "LeftArrow",
        mods = "ALT",
        action = act.SendString("b")
    }, {
        key = "RightArrow",
        mods = "ALT",
        action = act.SendString("\x1bf")
    }},
    mouse_bindings = { -- Ctrl-click will open the link under the mouse cursor
    {
        event = {
            Up = {
                streak = 1,
                button = 'Left'
            }
        },
        mods = 'CTRL',
        action = wezterm.action.OpenLinkAtMouseCursor
    }}
}

if wezterm.gui.get_appearance() == 'Dark' then
    config.color_scheme = 'Catppuccin Mocha' -- Или любая другая ваша темная тема
else
    config.color_scheme = 'Catppuccin Latte'
end

return config
