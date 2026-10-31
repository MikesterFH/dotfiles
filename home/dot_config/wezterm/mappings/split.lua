local wezterm = require "wezterm"
local act = wezterm.action

---Same distro selection as config/general.lua.
local function wsl_distro()
  local domains = wezterm.default_wsl_domains()
  local preferred = os.getenv "WEZTERM_WSL_DISTRO"
  if preferred and preferred ~= "" then
    for _, domain in ipairs(domains) do
      if domain.distribution == preferred then
        return preferred
      end
    end
  end
  return domains[1] and domains[1].distribution
end

---WSL shells run as a local `wsl.exe` program inside the mux server, so a plain
---spawn would start `wsl.exe --cd ~`. A WSL shell reports a Linux path via OSC 7
---(Windows shells report `/C:/...`), use it to start WSL in the same directory.
local function wsl_args(pane)
  local cwd = pane:get_current_working_dir()
  local path = cwd and cwd.file_path
  if not path or not path:match "^/" or path:match "^/%a:" then
    return nil
  end
  local distro = wsl_distro()
  if not distro then
    return nil
  end
  return { "wsl.exe", "-d", distro, "--cd", path }
end

local function command_for(pane)
  local command = { domain = "CurrentPaneDomain" }
  local args = wsl_args(pane)
  if args then
    command.args = args
  end
  return command
end

local function split(direction)
  return wezterm.action_callback(function(window, pane)
    local command = command_for(pane)
    local action
    if direction == "Down" then
      action = act.SplitVertical(command)
    else
      action = act.SplitHorizontal(command)
    end
    window:perform_action(action, pane)
  end)
end

return {
  down = split "Down",
  right = split "Right",
  tab = wezterm.action_callback(function(window, pane)
    window:perform_action(act.SpawnCommandInNewTab(command_for(pane)), pane)
  end),
}
