local wezterm = require "wezterm"
local config = wezterm.config_builder()

config.enable_scroll_bar = true
config.enable_wayland = true
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.default_cursor_style = "BlinkingUnderline"
config.cursor_blink_rate = 100
config.cursor_thickness = 2.5
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.warn_about_missing_glyphs = false

return config
