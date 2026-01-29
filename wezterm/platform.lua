local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	if wezterm.target_triple == "x86_64-pc-windows-msvc" then
		-- Windows
		config.wsl_domains = {
			{
				name = "WSL:Ubuntu",
				distribution = "Ubuntu",
				default_cwd = "~",
			},
		}
		config.default_domain = "WSL:Ubuntu"

		-- Launch Menu für verschiedene Shells
		config.launch_menu = {
			{
				label = "WSL Ubuntu",
				domain = { DomainName = "WSL:Ubuntu" },
			},
			{
				label = "Git Bash",
				args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l" },
				domain = { DomainName = "local" },
			},
			{
				label = "PowerShell",
				args = { "powershell.exe", "-NoLogo" },
				domain = { DomainName = "local" },
			},
			{
				label = "CMD",
				args = { "cmd.exe" },
				domain = { DomainName = "local" },
			},
		}
		config.window_decorations = "TITLE | RESIZE"
	elseif wezterm.target_triple:find("apple") then
		-- macOS
		config.window_decorations = "TITLE | RESIZE"
		config.macos_window_background_blur = 15
	elseif wezterm.target_triple:find("linux") then
		-- Linux
		config.enable_wayland = true
		config.window_decorations = "TITLE | RESIZE"
	end
end

return module
