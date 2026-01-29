local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

	tabline.setup({
		options = {
			icons_enabled = true,
			theme = "GruvboxDark",
			tabs_enabled = true,
		},
		sections = {
			tabline_a = { "mode" },
			tabline_b = { "workspace" },
			tabline_c = { " " },
			tab_active = {
				"index",
				{ "parent", padding = 0 },
				"/",
				{ "cwd", padding = { left = 0, right = 1 } },
				{ "zoomed", padding = 0 },
			},
			tab_inactive = { "index", { "process", padding = { left = 0, right = 1 } } },
			tabline_x = { "ram", "cpu" },
			tabline_y = { "datetime", "battery" },
			tabline_z = { "domain" },
		},
	})

	tabline.apply_to_config(config)
end

return module
