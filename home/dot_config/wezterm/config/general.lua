local Icons = require "utils.class.icon"
local fs = require("utils.fn").fs
local wt = require "wezterm"

local Config = {}

local function get_wsl_domains()
  local domains = wt.default_wsl_domains()
  local preferred = os.getenv "WEZTERM_WSL_DISTRO"
  if preferred and preferred ~= "" then
    for _, domain in ipairs(domains) do
      if domain.distribution == preferred then
        domains = { domain }
        break
      end
    end
  end

  for _, domain in ipairs(domains) do
    domain.default_prog = { "bash", "-i", "-l" }
  end
  return domains
end

if fs.platform().is_mac then
  Config.default_prog = { "/bin/zsh", "-l" }
elseif fs.platform().is_win then
  -- PowerShell 7 (pwsh, a Bootstrap Package): the only Windows shell whose
  -- profile (Documents\PowerShell) sets up mise, starship and the aliases.
  -- Windows PowerShell 5.1 reads Documents\WindowsPowerShell and would start
  -- without nvim on the PATH. See docs/adr/0015-default-shells.md.
  Config.default_prog = { "pwsh.exe", "-NoLogo" }

  Config.launch_menu = {
    {
      label = Icons.Progs["pwsh.exe"] .. " PowerShell",
      args = { "pwsh.exe", "-NoLogo" },
      cwd = "~",
    },
  }

  Config.wsl_domains = get_wsl_domains()
end

Config.default_cwd = fs.home()

Config.initial_cols = 120
Config.initial_rows = 40

-- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
Config.ssh_domains = {}

-- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
Config.unix_domains = {
  { name = "persistent" },
}
Config.default_gui_startup_args = { "connect", "persistent" }

return Config
