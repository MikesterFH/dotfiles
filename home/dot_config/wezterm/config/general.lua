local Icons = require "utils.class.icon"
local fs = require("utils.fn").fs
local wt = require "wezterm"

local Config = {}

local function find_git_bash()
  local candidates = {}
  local program_files = os.getenv "ProgramFiles"
  local program_files_x86 = os.getenv "ProgramFiles(x86)"
  local local_app_data = os.getenv "LOCALAPPDATA"
  local scoop = os.getenv "SCOOP"
  if not scoop or scoop == "" then
    scoop = fs.home() .. "\\scoop"
  end

  local function add_candidate(root, relative_path)
    if root and root ~= "" then
      candidates[#candidates + 1] = root .. relative_path
    end
  end

  add_candidate(program_files, "\\Git\\bin\\bash.exe")
  add_candidate(program_files_x86, "\\Git\\bin\\bash.exe")
  add_candidate(local_app_data, "\\Programs\\Git\\bin\\bash.exe")
  add_candidate(scoop, "\\apps\\git\\current\\bin\\bash.exe")

  for _, path in ipairs(candidates) do
    local file = io.open(path, "rb")
    if file then
      file:close()
      return path
    end
  end
end

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
  -- PowerShell 7 (pwsh, a Bootstrap Package): the default Windows shell. Its
  -- profile stub dot-sources ~\.config\powershell\profile.ps1 (mise, starship,
  -- aliases). Windows PowerShell 5.1 gets the same stub but lacks mise's chpwd
  -- hook. See docs/adr/0015-default-shells.md and 0020.
  Config.default_prog = { "pwsh.exe", "-NoLogo" }

  Config.launch_menu = {
    {
      label = Icons.Progs["pwsh.exe"] .. " PowerShell",
      args = { "pwsh.exe", "-NoLogo" },
      cwd = "~",
    },
  }

  local git_bash = find_git_bash()
  if git_bash then
    Config.launch_menu[#Config.launch_menu + 1] = {
      label = Icons.Progs["git"] .. " Git Bash",
      args = { git_bash, "-i", "-l" },
      domain = { DomainName = "local" },
      cwd = "~",
    }
  end

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
