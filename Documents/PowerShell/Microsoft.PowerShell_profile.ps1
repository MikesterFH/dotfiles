# Minimal PowerShell profile — aliases + starship prompt hook.
# Windows Target only; mirrors the handful of shell aliases from
# dot_bash_aliases/dot_zsh_aliases that don't depend on tools this repo
# doesn't yet provision on Windows (bat, eza, lazygit).

Set-Alias vim nvim

function ga { git add . }
function gc { param($m) git commit -m $m }
function gs { git status -s }

Invoke-Expression (&starship init powershell)
