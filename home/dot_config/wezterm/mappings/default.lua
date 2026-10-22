---@module "mappings.default"
---@author sravioli
---@license GNU-GPLv3

---@diagnostic disable-next-line: undefined-field
local wezterm = require "wezterm"
local act = wezterm.action
local key = require("utils.fn").key
local split = require "mappings.split"

local Config = {}

Config.disable_default_key_bindings = true
Config.leader = { key = "f", mods = "CTRL", timeout_milliseconds = 1000 }

-- Pass Ctrl+hjkl to Neovim (smart-splits.nvim sets IS_NVIM), else switch pane
local function nav(k, direction)
  return wezterm.action_callback(function(win, pane)
    if pane:get_user_vars().IS_NVIM == "true" then
      win:perform_action(act.SendKey { key = k, mods = "CTRL" }, pane)
    else
      win:perform_action(act.ActivatePaneDirection(direction), pane)
    end
  end)
end

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

local mappings = {
  { "<S-CR>", act.SendString "\x1b[13;2u", "newline in Copilot" },
  { "<C-Tab>", act.ActivateTabRelative(1), "next tab" },
  { "<C-S-Tab>", act.ActivateTabRelative(-1), "prev tab" },
  { "<C-d>", act.ActivateTabRelative(-1), "prev tab" },
  { "<C-u>", act.ActivateTabRelative(1), "next tab" },
  { "<C-h>", nav("h", "Left"), "pane left" },
  { "<C-j>", nav("j", "Down"), "pane down" },
  { "<C-k>", nav("k", "Up"), "pane up" },
  { "<C-l>", nav("l", "Right"), "pane right" },
  { "<M-CR>", act.ToggleFullScreen, "fullscreen" },
  { "<C-S-c>", act.CopyTo "Clipboard", "copy" },
  { "<C-S-v>", act.PasteFrom "Clipboard", "paste" },
  { "<C-S-f>", act.Search "CurrentSelectionOrEmptyString", "search" },
  { "<C-S-k>", act.ClearScrollback "ScrollbackOnly", "clear scrollback" },
  { "<C-S-l>", act.ShowDebugOverlay, "debug overlay" },
  { "<C-S-n>", act.SpawnWindow, "new window" },
  { "<C-S-p>", act.ActivateCommandPalette, "command palette" },
  { "<C-S-r>", act.ReloadConfiguration, "reload config" },
  { "<C-S-t>", act.SpawnTab "CurrentPaneDomain", "new pane" },
  {
    "<C-S-u>",
    act.CharSelect {
      copy_on_select = true,
      copy_to = "ClipboardAndPrimarySelection",
    },
    "char select",
  },
  { "<C-S-w>", act.CloseCurrentTab { confirm = true }, "close tab" },
  { "<C-S-z>", act.TogglePaneZoomState, "toggle zoom" },
  { "<PageUp>", act.ScrollByPage(-1), "" },
  { "<PageDown>", act.ScrollByPage(1), "" },
  { "<C-S-Insert>", act.PasteFrom "PrimarySelection", "" },
  { "<C-Insert>", act.CopyTo "PrimarySelection", "" },
  { "<C-S-Space>", act.QuickSelect, "quick select" },
  {
    "<S-M-t>",
    act.ShowLauncherArgs {
      title = "  Search:",
      flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS",
    },
    "new window",
  },

  ---macOS standard shortcuts
  { "<W-q>", act.QuitApplication, "quit" },
  { "<W-c>", act.CopyTo "Clipboard", "copy" },
  { "<W-v>", act.PasteFrom "Clipboard", "paste" },
  { "<W-n>", act.SpawnWindow, "new window" },
  { "<W-t>", act.SpawnTab "CurrentPaneDomain", "new tab" },
  { "<W-w>", act.CloseCurrentTab { confirm = true }, "close tab" },
  { "<W-m>", act.Hide, "minimize" },
  { "<W-h>", act.HideApplication, "hide app" },

  ---quick split and nav
  { '<C-S-">', split.right, "vsplit" },
  { "<C-S-%>", split.down, "hsplit" },
  { "<C-M-h>", act.ActivatePaneDirection "Left", "move left" },
  { "<C-M-j>", act.ActivatePaneDirection "Down", "mode down" },
  { "<C-M-k>", act.ActivatePaneDirection "Up", "move up" },
  { "<C-M-l>", act.ActivatePaneDirection "Right", "move right" },

  ---psmux-compatible leader mappings
  { "<leader>-", split.down, "split down" },
  { "<leader>|", split.right, "split right" },
  { "<leader>v", act.ActivateCopyMode, "copy mode" },
  { "<leader>r", act.ReloadConfiguration, "reload config" },
  { "<leader>h", resize "Left", "resize left (repeat h/j/k/l)" },
  { "<leader>j", resize "Down", "resize down (repeat h/j/k/l)" },
  { "<leader>k", resize "Up", "resize up (repeat h/j/k/l)" },
  { "<leader>l", resize "Right", "resize right (repeat h/j/k/l)" },
  { "<leader>m", act.TogglePaneZoomState, "toggle zoom" },
  { "<leader>n", act.SpawnTab "CurrentPaneDomain", "new tab" },
  {
    "<leader>,",
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
  { "<leader>x", act.CloseCurrentPane { confirm = true }, "close pane" },

  ---workspaces
  {
    "<leader><S-w>",
    act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" },
    "select workspace",
  },
  {
    "<leader><S-n>",
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
    "create or switch workspace",
  },
  { "<leader>[", act.SwitchWorkspaceRelative(-1), "previous workspace" },
  { "<leader>]", act.SwitchWorkspaceRelative(1), "next workspace" },
  {
    "<leader><S-x>",
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
            .. (wezterm.target_triple:find("windows") and "\\wezterm.exe" or "/wezterm")
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
    "delete workspace (confirm)",
  },

  ---key tables
  { "<leader><S-/>", act.ActivateKeyTable { name = "help_mode", one_shot = true }, "help" },
  {
    "<leader>w",
    act.ActivateKeyTable { name = "window_mode", one_shot = false },
    "window mode",
  },
  {
    "<leader>f",
    act.ActivateKeyTable { name = "font_mode", one_shot = false },
    "font mode",
  },
  { "<leader>c", act.ActivateCopyMode, "copy mode" },
  { "<leader>s", act.Search "CurrentSelectionOrEmptyString", "search mode" },
  { "<leader>p", act.ActivateKeyTable { name = "pick_mode" }, "pick mode" },
}

for i = 1, 24 do
  mappings[#mappings + 1] =
    { "<S-F" .. i .. ">", act.ActivateTab(i - 1), "activate tab " .. i }
end

Config.keys = {}
for _, map_tbl in ipairs(mappings) do
  key.map(map_tbl[1], map_tbl[2], Config.keys)
end

return Config
