local wezterm = require "wezterm"
local act = wezterm.action

local function split(direction)
  return wezterm.action_callback(function(window, pane)
    local command = { domain = "CurrentPaneDomain" }

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
}
