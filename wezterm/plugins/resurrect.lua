local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

	config.keys = {
		{
			key = "w",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
			end),
		},
		{
			key = "W",
			mods = "ALT",
			action = resurrect.window_state.save_window_action(),
		},
		{
			key = "T",
			mods = "ALT",
			action = resurrect.tab_state.save_tab_action(),
		},
		{
			key = "s",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
				resurrect.window_state.save_window_action()
			end),
		},
	}

	wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)
end

return module
