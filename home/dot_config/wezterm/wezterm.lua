local Config = require("utils.class.config"):new()

local fs = require("utils.fn").fs
for _, name in ipairs { "colorschemes", "fonts", "font-sizes", "font-leadings" } do
  fs.refresh_dir(fs.pathconcat(require("wezterm").config_dir, "picker", "assets", name))
end

require "events.update-status"
require "events.format-tab-title"
require "events.new-tab-button-click"
require "events.augment-command-palette"
require "events.format-window-title"

return Config:add("config"):add "mappings"
