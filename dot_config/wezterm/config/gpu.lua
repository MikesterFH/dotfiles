local fs = require("utils.fn").fs

local Config = {}

if fs.platform().is_win then
  Config.front_end = "OpenGL"
else
  Config.front_end = "WebGpu"
  Config.webgpu_force_fallback_adapter = false

  ---switch to low power mode when battery is low
  ---@diagnostic disable-next-line: undefined-field
  local battery = require("wezterm").battery_info()[1]
  Config.webgpu_power_preference = (battery and battery.state_of_charge < 0.35)
      and "LowPower"
    or "HighPerformance"

  Config.webgpu_preferred_adapter = require("utils.gpu"):pick_best()
end

return Config
