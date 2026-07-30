---Based on: nvim_tmux_term colorscheme
---@module "picker.assets.colorschemes.future-term"
---@author michi
---@license GNU-GPLv3

---@class PickList
local M = {}

local color = require("utils").fn.color

M.scheme = {
  background = "#010B17",
  foreground = "#EBDDF4",
  cursor_bg = "#38FF9C",
  cursor_fg = "#000000",
  cursor_border = "#38FF9C",
  selection_fg = "#000000",
  selection_bg = "#38FF9C",
  scrollbar_thumb = "#62686C",
  split = "#62686C",
  ansi = {
    "#0B3B61",
    "#FF3A3A",
    "#52FFCF",
    "#FFF383",
    "#1376F8",
    "#C792EA",
    "#FF5DD4",
    "#15FCA2",
  },
  brights = {
    "#62686C",
    "#FF54B0",
    "#73FFD8",
    "#FCF4AD",
    "#378DFE",
    "#AE81FF",
    "#FF69D7",
    "#5FFBBE",
  },
  indexed = {},
  compose_cursor = "#FF5DD4",
  visual_bell = "#0B3B61",
  copy_mode_active_highlight_bg = { Color = "#0B3B61" },
  copy_mode_active_highlight_fg = { Color = "#EBDDF4" },
  copy_mode_inactive_highlight_bg = { Color = "#010B17" },
  copy_mode_inactive_highlight_fg = { Color = "#EBDDF4" },
  quick_select_label_bg = { Color = "#FF3A3A" },
  quick_select_label_fg = { Color = "#EBDDF4" },
  quick_select_match_bg = { Color = "#FFF383" },
  quick_select_match_fg = { Color = "#000000" },
  tab_bar = {
    background = "#011627",
    inactive_tab_edge = "#011627",
    active_tab = { bg_color = "#010B17", fg_color = "#EBDDF4", italic = false },
    inactive_tab = { bg_color = "#011627", fg_color = "#62686C" },
    inactive_tab_hover = { bg_color = "#0B3B61", fg_color = "#EBDDF4", italic = true },
    new_tab = { bg_color = "#011627", fg_color = "#62686C" },
    new_tab_hover = { bg_color = "#38FF9C", fg_color = "#000000", italic = false },
  },
}

function M.get()
  return { id = "future-term", label = "futureTerm" }
end

function M.activate(Config, callback_opts)
  local theme = M.scheme
  color.set_scheme(Config, theme, callback_opts.id)
end

return M
