local Icons = require "utils.class.icon"
local fs = require("utils.fn").fs

local Config = {}

if fs.platform().is_mac then
  Config.default_prog = { "/bin/zsh", "-l" }
elseif fs.platform().is_win then
  Config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l" }

  Config.launch_menu = {
    {
      label = Icons.Progs["git"] .. " Git Bash",
      args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l" },
      domain = { DomainName = "local" },
      cwd = "~",
    },
    {
      label = Icons.Progs["pwsh.exe"] .. " PowerShell",
      args = { "powershell" },
      cwd = "~",
    },
  }

  -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
  Config.wsl_domains = {
    {
      name = "WSL:Ubuntu",
      distribution = "Ubuntu",
      default_cwd = "~",
      default_prog = { "bash", "-i", "-l" },
    },
  }
end

Config.default_cwd = fs.home()

Config.initial_cols = 120
Config.initial_rows = 40

-- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
Config.ssh_domains = {}

-- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
Config.unix_domains = {}

return Config
