# Minimal PowerShell profile — aliases + starship prompt hook.
# Windows Target only; mirrors the handful of shell aliases from
# dot_bash_aliases/dot_zsh_aliases that don't depend on tools this repo
# doesn't provision on Windows (eza).

Set-Alias vim nvim
Set-Alias c clear

function ga { git add . }
function gc { param($m) git commit -m $m }
function gs { git status -s }

if (Get-Command starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (&starship init powershell)
}

# mise: node, python for nvim's Mason, see docs/adr/0011-nvim-toolchain.md
if (Get-Command mise -ErrorAction SilentlyContinue) {
  (&mise activate pwsh) | Out-String | Invoke-Expression
}

if ((Get-Module PSReadLine).Version -ge [version]"2.1.0" -and -not [Console]::IsOutputRedirected) {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle InlineView
  Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar
  Set-PSReadLineKeyHandler -Key Alt+f -Function AcceptNextSuggestionWord
}

$prompt = ""
function Invoke-Starship-PreCommand {
  $current_location = $executionContext.SessionState.Path.CurrentLocation
  if ($current_location.Provider.Name -eq "FileSystem") {
    $ansi_escape = [char]27
    $provider_path = $current_location.ProviderPath -replace "\\", "/"
    $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
  }
  $host.ui.Write($prompt)
}
