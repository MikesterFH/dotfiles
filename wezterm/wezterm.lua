-- Pull in the wezterm API
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- Module laden
local appearance = require("appearance")
local keybindings = require("keybindings")
local platform = require("platform")
local tabline_config = require("plugins/tabline")

-- Konfiguration zusammenführen
appearance.apply_to_config(config)
keybindings.apply_to_config(config)
platform.apply_to_config(config)
tabline_config.apply_to_config(config)

-- ===== BASIC SETTINGS =====
config.automatically_reload_config = true
config.check_for_updates = true
config.window_close_confirmation = "NeverPrompt"

-- ===== MOUSE BINDINGS =====
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.PasteFrom("Clipboard"),
	},
	{
		event = { Down = { streak = 3, button = "Left" } },
		action = act.SelectTextAtMouseCursor("Line"),
	},
}

-- ===== WINDOW TITLE FORMATTING =====
wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
	local zoomed = ""
	if tab.active_pane.is_zoomed then
		zoomed = "[Z] "
	end

	local index = ""
	if #tabs > 1 then
		index = string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
	end

	return zoomed .. index .. tab.active_pane.title
end)

return config
