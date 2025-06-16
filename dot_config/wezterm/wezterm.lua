local wezterm = require 'wezterm'

local act = wezterm.action

local config = {
    adjust_window_size_when_changing_font_size = false,
    enable_tab_bar = false,
    font_size = 14.0,
    font = wezterm.font('JetBrains Mono'),
    macos_window_background_blur = 30,
    window_background_opacity = 0.92,
    keys = {{
        key = "LeftArrow",
        mods = "OPT",
        action = act.SendString("\x1bb")
    }, {
        key = "RightArrow",
        mods = "OPT",
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
