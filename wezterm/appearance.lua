local module = {}

function module.apply_to_config(config)
	-- Font & Appearance
	config.font_size = 14
	config.line_height = 1.1

	-- Load custom color scheme
	config.colors = require("colors/nvim_tmux_term")

	config.window_padding = {
		left = 8,
		right = 8,
		top = 8,
		bottom = 8,
	}

	-- Transparency and blur
	config.window_background_opacity = 0.75
	config.macos_window_background_blur = 20

	config.scrollback_lines = 10000
	config.enable_scroll_bar = false

	-- Inactive pane styling
	config.inactive_pane_hsb = {
		saturation = 0.8,
		brightness = 0.6,
	}

	-- Tab bar
	config.enable_tab_bar = true
	config.tab_bar_at_bottom = true
	config.use_fancy_tab_bar = true
	config.hide_tab_bar_if_only_one_tab = false
	config.tab_max_width = 30
	config.show_new_tab_button_in_tab_bar = false
end

return module
