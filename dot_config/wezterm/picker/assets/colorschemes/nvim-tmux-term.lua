---@module "picker.assets.colorschemes.nvim-tmux-term"
---@author sravioli
---@license GNU-GPLv3

---@class PickList
local M = {}

local color = require("utils").fn.color

M.scheme = {
  foreground = "#ECDEF5",
  background = "#010C17",
  cursor_bg = "#38FF9D",
  cursor_fg = "#010C17",
  cursor_border = "#38FF9D",
  selection_bg = "#38FF9C",
  selection_fg = "#ECDEF5",
  scrollbar_thumb = "#62686D",
  split = "#0B3B61",
  ansi = {
    "#0B3B61",
    "#FF3A3A",
    "#52FFD0",
    "#FFF383",
    "#1376F9",
    "#C792EA",
    "#FF5ED4",
    "#15FCA2",
  },
  brights = {
    "#62686D",
    "#FF54B1",
    "#73FFD8",
    "#FCF5AE",
    "#378DFF",
    "#AE81FF",
    "#FF6AD7",
    "#60FCBF",
  },
  indexed = {},
  compose_cursor = "#38FF9D",
  copy_mode_active_highlight_bg = { Color = "#38FF9C" },
  copy_mode_active_highlight_fg = { Color = "#ECDEF5" },
  copy_mode_inactive_highlight_bg = { Color = "#62686D" },
  copy_mode_inactive_highlight_fg = { Color = "#ECDEF5" },
  quick_select_label_bg = { Color = "#FF3A3A" },
  quick_select_label_fg = { Color = "#010C17" },
  quick_select_match_bg = { Color = "#FFF383" },
  quick_select_match_fg = { Color = "#010C17" },
  visual_bell = "#38FF9C",
  tab_bar = {
    background = "#011627",
    inactive_tab_edge = "#011627",
    active_tab = { bg_color = "#010C17", fg_color = "#ECDEF5", italic = false },
    inactive_tab = { bg_color = "#011627", fg_color = "#62686D" },
    inactive_tab_hover = { bg_color = "#0B3B61", fg_color = "#ECDEF5", italic = true },
    new_tab = { bg_color = "#011627", fg_color = "#62686D" },
    new_tab_hover = { bg_color = "#38FF9D", fg_color = "#010C17", italic = false },
  },
}

function M.get()
  return { id = "nvim-tmux-term", label = "Nvim Tmux Term" }
end

function M.activate(Config, callback_opts)
  local theme = M.scheme
  color.set_scheme(Config, theme, callback_opts.id)
end

return M
