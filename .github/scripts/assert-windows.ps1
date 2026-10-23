# Asserts the chezmoi Target State rendered by CI for the native Windows
# Target matches expectations, for a given machine Profile (personal/dev/
# dev-server, see docs/adr/0004-machine-profiles.md).
# Usage: assert-windows.ps1 -Dest <dest-dir> -MachineProfile <profile>
#
# Parameter is -MachineProfile, not -Profile: $Profile is a PowerShell
# automatic variable (path to the user's profile script) — reusing the name
# would shadow it.
#
# Every assertion runs and every failure is reported, instead of stopping at
# the first one.
param(
    [Parameter(Mandatory = $true)]
    [string]$Dest,

    [Parameter(Mandatory = $true)]
    [ValidateSet("personal", "dev", "dev-server")]
    [string]$MachineProfile
)

$script:failed = $false

function Assert-FileExists {
    param([string]$RelativePath)
    $path = Join-Path $Dest $RelativePath
    if (Test-Path -Path $path -PathType Leaf) {
        Write-Host "[OK]   present: $RelativePath"
    } else {
        Write-Host "[FAIL] expected file missing: $RelativePath"
        $script:failed = $true
    }
}

function Assert-Absent {
    param([string]$RelativePath)
    $path = Join-Path $Dest $RelativePath
    if (Test-Path -Path $path) {
        Write-Host "[FAIL] unexpected path present: $RelativePath"
        $script:failed = $true
    } else {
        Write-Host "[OK]   absent: $RelativePath"
    }
}

Write-Host "--- profile=$MachineProfile ---"

# Windows Target has no bash/zsh of its own
Assert-Absent ".bashrc"
Assert-Absent ".bash_aliases"
Assert-Absent ".zshrc"
Assert-Absent ".zprofile"
Assert-Absent ".zsh_aliases"
Assert-Absent ".local"
Assert-FileExists ".psmux.conf"

$psmuxConfig = Get-Content -LiteralPath (Join-Path $Dest ".psmux.conf") -Raw -ErrorAction SilentlyContinue
if ($psmuxConfig -notmatch 'source-file ~/\.psmux\.conf' -or
    $psmuxConfig -notmatch 'bind-key -n C-h if-shell' -or
    $psmuxConfig -match 'psmux-battery|@\{?battery_display|psmux-vim-navigator') {
    Write-Host "[FAIL] psmux config: reload, Neovim navigation, or removed plugin expectations violated"
    $script:failed = $true
} else {
    Write-Host "[OK]   psmux config: dedicated reload, Neovim navigation, no battery or navigator poller"
}

# tmux config IS deployed on Windows, unconditional across every profile —
# psmux reads the same tmux.conf, see
# docs/adr/0005-psmux-for-windows-tmux-parity.md
Assert-FileExists ".config\tmux\tmux.conf"

# German spell files for nvim, pulled in by .chezmoiexternal.toml.tmpl, see
# docs/adr/0010-nvim-spell-files-as-chezmoi-externals.md
Assert-FileExists "AppData\Local\nvim-data\site\spell\de.utf-8.spl"
Assert-FileExists "AppData\Local\nvim-data\site\spell\de.utf-8.sug"

# Global mise tools (node, python for nvim's Mason), see
# docs/adr/0011-nvim-toolchain.md
Assert-FileExists ".config\mise\config.toml"
# CLI tools come from mise on Linux only (docs/adr/0012-linux-cli-tools-via-mise.md);
# Windows keeps them in the winget manifest.
$miseConfigPath = Join-Path $Dest ".config\mise\config.toml"
if ((Test-Path -Path $miseConfigPath -PathType Leaf) -and (Select-String -Path $miseConfigPath -Pattern "aqua:" -SimpleMatch -Quiet)) {
    Write-Host "[FAIL] mise config: aqua CLI tools should be Linux-only"
    $script:failed = $true
} else {
    Write-Host "[OK]   mise config: no aqua CLI tools"
}

# PowerShell profile, Windows-only, unconditional across every profile
Assert-FileExists "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# Git identity: which config.local.* files exist depends on profile (see
# docs/adr/0004-machine-profiles.md) — personal -> personal+work,
# dev -> work+client, dev-server -> personal+work.
switch ($MachineProfile) {
    { $_ -in "personal", "dev-server" } {
        Assert-FileExists ".config\git\config.local.personal"
        Assert-FileExists ".config\git\config.local.work"
        Assert-Absent ".config\git\config.local.client"
    }
    "dev" {
        Assert-Absent ".config\git\config.local.personal"
        Assert-FileExists ".config\git\config.local.work"
        Assert-FileExists ".config\git\config.local.client"
    }
}

# GUI-app configs: dev-server's Application list holds only CLI tools, so it gets none;
# personal/dev's Application list carries every app (see .chezmoi.toml.tmpl).
if ($MachineProfile -eq "dev-server") {
    Assert-Absent ".config\wezterm"
    Assert-Absent "AppData\Roaming\Code"
    Assert-Absent "AppData\Roaming\Zed"
    Assert-Absent "AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe"
} else {
    Assert-FileExists ".config\wezterm\wezterm.lua"
    Assert-FileExists "AppData\Roaming\Code\User\settings.json"
    Assert-FileExists "AppData\Roaming\Zed\keymap.json"
    Assert-FileExists "AppData\Roaming\Zed\settings.json"
    Assert-FileExists "AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
}

# macOS Application manifest (Homebrew) is macOS-only, and the Linux
# (Debian/apt) Application manifest is Linux-only, see
# docs/adr/0006-application-category-and-profile-manifests.md
Assert-Absent ".config\homebrew"
Assert-Absent ".config\apt-packages.txt"

# Windows Application manifest (winget), see
# docs/adr/0006-application-category-and-profile-manifests.md: one package
# entry per app in the Profile's Application list that has a winget package
# ID (iterm2 doesn't, so never expected here). dev-server gets CLI tools only.
$wingetManifestPath = Join-Path $Dest ".config\winget\packages.json"
Assert-FileExists ".config\winget\packages.json"
if (Test-Path -Path $wingetManifestPath -PathType Leaf) {
    $wingetManifest = Get-Content -Path $wingetManifestPath -Raw | ConvertFrom-Json
    $packageIds = @($wingetManifest.Sources[0].Packages | ForEach-Object { $_.PackageIdentifier })
    # CLI tools on every profile (see docs/adr/0008-cli-tools-are-applications.md);
    # no tmux entry, psmux (a Bootstrap Package) stands in for it.
    $expectedIds = @(
        "dandavison.delta", "Starship.Starship", "Neovim.Neovim", "junegunn.fzf",
        "ajeetdsouza.zoxide", "sxyazi.yazi", "charmbracelet.glow", "sharkdp.bat",
        "JesseDuffield.lazygit", "tree-sitter.tree-sitter-cli",
        "BurntSushi.ripgrep.MSVC", "sharkdp.fd", "Kitware.CMake"
    )
    if ($MachineProfile -ne "dev-server") {
        $expectedIds += @("wez.wezterm", "Microsoft.VisualStudioCode", "Zed.Zed", "Microsoft.WindowsTerminal", "DEVCOM.JetBrainsMonoNerdFont")
    }
    foreach ($id in $expectedIds) {
        if ($packageIds -contains $id) {
            Write-Host "[OK]   winget manifest: $id present"
        } else {
            Write-Host "[FAIL] winget manifest: $id missing"
            $script:failed = $true
        }
    }
    $extraIds = @($packageIds | Where-Object { $expectedIds -notcontains $_ })
    if ($extraIds.Count -gt 0) {
        Write-Host "[FAIL] winget manifest: unexpected extra package(s) present: $($extraIds -join ', ')"
        $script:failed = $true
    }
}

# Yazi reads ~/.config/yazi on Windows too (YAZI_CONFIG_HOME, set by the
# run_after_set-yazi-env-windows script); no separate AppData copy.
Assert-FileExists ".config\yazi\yazi.toml"
Assert-FileExists ".config\yazi\package.toml"
Assert-Absent "AppData\Roaming\yazi"

# Global git hooks (docs/adr/0009-global-git-hooks.md): agent-trailer
# filter plus the pass-through to each repo's own hooks.
Assert-FileExists ".config\git\hooks\commit-msg"
Assert-FileExists ".config\git\hooks\run-repo-hook"

# Rendered git config: autocrlf must be "true", never "input"
$gitConfigPath = Join-Path $Dest ".config\git\config"
if (Test-Path -Path $gitConfigPath -PathType Leaf) {
    $gitConfig = Get-Content -Path $gitConfigPath -Raw
    if ($gitConfig -match '(?m)^\s*autocrlf\s*=\s*true\s*$') {
        Write-Host "[OK]   git config: autocrlf = true"
    } else {
        Write-Host "[FAIL] git config: autocrlf = true not found in $gitConfigPath"
        $script:failed = $true
    }
    if ($gitConfig -match '(?m)^\s*autocrlf\s*=\s*input\s*$') {
        Write-Host "[FAIL] git config: autocrlf = input present (should be true on this Target)"
        $script:failed = $true
    }
} else {
    Write-Host "[FAIL] expected file missing: .config\git\config"
    $script:failed = $true
}

# SKIP_FILES/SKIP_DIRS (from .chezmoiignore) must not have leaked through.
# Kept in sync by hand with the catch-all list at the bottom of
# .chezmoiignore (and its assert-unix.sh counterpart) — update all three
# together.
$skipNames = @(
    "README.md", "readme.md", "README", "LICENSE", "CHANGELOG.md", "HELP.md",
    "which-key.yaml", "Thumbs.db", "node_modules", "__pycache__", "venv"
)
$skipHits = Get-ChildItem -Path $Dest -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $skipNames -contains $_.Name }
if ($skipHits) {
    Write-Host "[FAIL] SKIP_FILES/SKIP_DIRS matches found:"
    $skipHits | ForEach-Object { Write-Host "  $($_.FullName)" }
    $script:failed = $true
} else {
    Write-Host "[OK]   no SKIP_FILES/SKIP_DIRS matches under $Dest"
}

if ($script:failed) {
    Write-Error "One or more assertions failed (profile=$MachineProfile)."
    exit 1
}

Write-Host "All Windows Target assertions passed (profile=$MachineProfile)."
