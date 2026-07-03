local wezterm = require 'wezterm'

local act = wezterm.action

local config = {
    adjust_window_size_when_changing_font_size = false,
    enable_tab_bar = false,
    max_fps = 120,
    font_size = 14.0,
    font = wezterm.font('JetBrains Mono'),
    window_background_opacity = 0.8,
    macos_window_background_blur = 50,
    keys = {{
        key = "LeftArrow",
        mods = "OPT",
        action = act.SendString("\x1bb")
    }, {
        key = "RightArrow",
        mods = "OPT",
        action = act.SendString("\x1bf")
    }},
    window_decorations = "RESIZE",
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

config.color_scheme = 'Rosé Pine Moon'

config.default_cursor_style = 'SteadyBlock'
config.colors = {
  cursor_bg = '#c4a7e7',
  cursor_fg = '#191724',
}

config.window_close_confirmation = "NeverPrompt"

return config
