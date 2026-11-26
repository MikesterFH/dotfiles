---@module "mappings.leader"
---Mappings of the `leader_mode` key table, entered with <C-f>.
---<C-f> is not a wezterm `config.leader`: it is forwarded unchanged to tmux/psmux/ssh
---panes (see utils.passthrough), so a remote tmux with the same prefix keeps working.

---@diagnostic disable-next-line: undefined-field
local wezterm = require "wezterm"
local act = wezterm.action
local split = require "mappings.split"

local function resize(direction)
  return act.Multiple {
    act.AdjustPaneSize { direction, 5 },
    act.ActivateKeyTable {
      name = "resize_mode",
      one_shot = false,
      timeout_milliseconds = 1000,
      until_unknown = true,
    },
  }
end

return {
  { "<ESC>", "PopKeyTable", "exit" },
  { "<C-f>", act.SendKey { key = "f", mods = "CTRL" }, "send C-f" },
  {
    "t",
    act.ShowLauncherArgs {
      title = "  Search:",
      flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS",
    },
    "shell launcher",
  },

  ---psmux-compatible leader mappings
  { "-", split.down, "split down" },
  { "|", split.right, "split right" },
  { "v", act.ActivateCopyMode, "copy mode" },
  { "r", act.ReloadConfiguration, "reload config" },
  { "h", resize "Left", "resize left" },
  { "j", resize "Down", "resize down" },
  { "k", resize "Up", "resize up" },
  { "l", resize "Right", "resize right" },
  { "m", act.TogglePaneZoomState, "toggle zoom" },
  { "n", split.tab, "new tab" },
  {
    ",",
    act.PromptInputLine {
      description = "Tab name (empty = reset):",
      action = wezterm.action_callback(function(window, _, line)
        if line == nil then
          return
        end
        window:active_tab():set_title(line:match "^%s*(.-)%s*$")
      end),
    },
    "rename tab",
  },
  { "x", act.CloseCurrentPane { confirm = true }, "close pane" },

  ---workspaces
  { "<S-w>", act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" }, "select workspace" },
  {
    "<S-n>",
    act.PromptInputLine {
      description = "Workspace name (create or switch):",
      action = wezterm.action_callback(function(window, pane, line)
        if line == nil then
          return
        end
        local name = line:match "^%s*(.-)%s*$"
        if name == "" then
          window:toast_notification("WezTerm", "Workspace name must not be empty.", nil, 4000)
          return
        end
        local spawn = { domain = "CurrentPaneDomain" }
        local cwd = pane:get_current_working_dir()
        if cwd and cwd.scheme == "file" then
          spawn.cwd = cwd.file_path
        end
        window:perform_action(act.SwitchToWorkspace { name = name, spawn = spawn }, pane)
      end),
    },
    "new/switch workspace",
  },
  { "[", act.SwitchWorkspaceRelative(-1), "prev workspace" },
  { "]", act.SwitchWorkspaceRelative(1), "next workspace" },
  {
    "<S-x>",
    wezterm.action_callback(function(window, pane)
      local workspace = window:active_workspace()
      window:perform_action(act.InputSelector {
        title = 'Delete workspace "' .. workspace .. '"?',
        description = "All tabs, panes and running processes will be terminated.",
        choices = {
          { id = "cancel", label = "Cancel" },
          { id = "delete", label = "Delete workspace and terminate all its processes" },
        },
        action = wezterm.action_callback(function(confirm_window, _, id)
          if id ~= "delete" then
            return
          end
          local pane_ids = {}
          local current_id = pane:pane_id()
          local close_current = false
          for _, mux_window in ipairs(wezterm.mux.all_windows()) do
            if mux_window:get_workspace() == workspace then
              for _, tab in ipairs(mux_window:tabs()) do
                for _, target in ipairs(tab:panes()) do
                  if target:pane_id() ~= current_id then
                    pane_ids[#pane_ids + 1] = target:pane_id()
                  else
                    close_current = true
                  end
                end
              end
            end
          end
          if close_current then
            pane_ids[#pane_ids + 1] = current_id
          end
          local executable = wezterm.executable_dir
            .. (wezterm.target_triple:find "windows" and "\\wezterm.exe" or "/wezterm")
          for _, pane_id in ipairs(pane_ids) do
            local success, _, stderr = wezterm.run_child_process {
              executable, "cli", "--no-auto-start", "kill-pane", "--pane-id", tostring(pane_id),
            }
            if not success then
              wezterm.log_error("Failed to delete workspace pane " .. pane_id .. ": " .. stderr)
              confirm_window:toast_notification(
                "WezTerm", "Workspace deletion stopped: " .. stderr, nil, 6000
              )
              return
            end
          end
        end),
      }, pane)
    end),
    "delete workspace",
  },

  ---key tables
  { "<S-/>", act.ActivateKeyTable { name = "help_mode", one_shot = true }, "help" },
  { "w", act.ActivateKeyTable { name = "window_mode", one_shot = false }, "window mode" },
  { "f", act.ActivateKeyTable { name = "font_mode", one_shot = false }, "font mode" },
  { "c", act.ActivateCopyMode, "copy mode" },
  { "s", act.Search "CurrentSelectionOrEmptyString", "search mode" },
  { "p", act.ActivateKeyTable { name = "pick_mode" }, "pick mode" },
}
