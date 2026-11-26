---@module "utils.passthrough"
---Detects panes whose foreground program owns the keyboard (tmux, psmux, ssh, ...).
---Keys that collide with those programs (leader, Ctrl+hjkl) are forwarded to them.

local M = {}

---Programs that receive the leader and Ctrl+hjkl untouched. `ssh` covers a remote
---tmux, since wezterm cannot see processes on the other side of the connection.
M.programs = {
  ssh = true,
  mosh = true,
  ["mosh-client"] = true,
  et = true,
  tmux = true,
  psmux = true,
  pmux = true,
}

local function basename(path)
  if not path or path == "" then
    return nil
  end
  local name = path:match "([^/\\]+)$" or path
  return (name:gsub("%.exe$", ""):lower())
end

---Returns true when keys should be forwarded to the program running in `pane`.
---Checks the local foreground process first, then the `WEZTERM_PROG` user var set by
---wezterm's shell integration (needed for panes in mux/unix domains).
---@param pane wt.Pane
---@return boolean
function M.active(pane)
  local ok, name = pcall(pane.get_foreground_process_name, pane)
  if ok and M.programs[basename(name)] then
    return true
  end

  local prog = pane:get_user_vars().WEZTERM_PROG
  if prog and prog ~= "" then
    for word in prog:gmatch "%S+" do
      -- skip `VAR=value` prefixes and sudo/env wrappers
      if not word:find "=" and word ~= "sudo" and word ~= "env" then
        return M.programs[basename(word)] == true
      end
    end
  end

  return false
end

return M
