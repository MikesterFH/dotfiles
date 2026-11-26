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
local passthrough = require "utils.passthrough"

-- Pass Ctrl+hjkl to Neovim (smart-splits.nvim sets IS_NVIM) and to tmux/ssh panes
-- (vim-tmux-navigator), else switch wezterm pane
local function nav(k, direction)
  return wezterm.action_callback(function(win, pane)
    if pane:get_user_vars().IS_NVIM == "true" or passthrough.active(pane) then
      win:perform_action(act.SendKey { key = k, mods = "CTRL" }, pane)
    else
      win:perform_action(act.ActivatePaneDirection(direction), pane)
    end
  end)
end

-- <C-f> is the leader. In tmux/psmux/ssh panes it goes straight to the program, so
-- a (remote) tmux with the same prefix works. Elsewhere it opens `leader_mode`.
local leader = wezterm.action_callback(function(win, pane)
  if passthrough.active(pane) then
    win:perform_action(act.SendKey { key = "f", mods = "CTRL" }, pane)
  else
    win:perform_action(act.ActivateKeyTable {
      name = "leader_mode",
      one_shot = true,
      timeout_milliseconds = 1000,
    }, pane)
  end
end)

local mappings = {
  { "<C-f>", leader, "leader (forwarded to tmux/ssh)" },
  {
    "<W-f>",
    act.ActivateKeyTable { name = "leader_mode", one_shot = true, timeout_milliseconds = 1000 },
    "wezterm leader (also in tmux/ssh)",
  },
  { "<S-CR>", act.SendString "\x1b[13;2u", "newline in Copilot" },
  { "<C-Tab>", act.ActivateTabRelative(1), "next tab" },
  { "<C-S-Tab>", act.ActivateTabRelative(-1), "prev tab" },
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
  { "<C-S-t>", split.tab, "new pane" },
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
  ---macOS standard shortcuts
  { "<W-q>", act.QuitApplication, "quit" },
  { "<W-c>", act.CopyTo "Clipboard", "copy" },
  { "<W-v>", act.PasteFrom "Clipboard", "paste" },
  { "<W-n>", act.SpawnWindow, "new window" },
  { "<W-t>", split.tab, "new tab" },
  { "<W-w>", act.CloseCurrentTab { confirm = true }, "close tab" },
  { "<W-m>", act.Hide, "minimize" },
  { "<W-h>", act.HideApplication, "hide app" },

  ---quick split and nav
  { '<C-S-">', split.right, "vsplit" },
  { "<C-S-%>", split.down, "hsplit" },
  { "<W-S-h>", act.ActivatePaneDirection "Left", "move left" },
  { "<W-S-j>", act.ActivatePaneDirection "Down", "move down" },
  { "<W-S-k>", act.ActivatePaneDirection "Up", "move up" },
  { "<W-S-l>", act.ActivatePaneDirection "Right", "move right" },

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
