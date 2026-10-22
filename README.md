# dotfiles

Personal configuration for macOS, Linux (including WSL), and native Windows, deployed and kept in sync via [chezmoi](https://www.chezmoi.io/).

This repo *is* chezmoi's **Source Dir** — its `home/` folder (selected by `.chezmoiroot`) is laid out to mirror `$HOME` using chezmoi's naming convention (e.g. `dot_bashrc` → `~/.bashrc`), not to be cloned and used directly. See `CONTEXT.md` for the vocabulary used throughout this repo and `docs/adr/` for the reasoning behind the bigger decisions (why chezmoi, why this repo is the Source Dir, why copy+apply instead of live symlinks).

## Supported Targets

| Target | What gets deployed |
| --- | --- |
| macOS | bash, zsh, tmux, git, starship, wezterm, VS Code, nvim, zed, Yazi, iTerm2 |
| Linux / WSL | same as macOS, minus iTerm2 |
| Native Windows | git, starship, wezterm, VS Code, nvim, zed, Yazi, tmux (via [psmux](https://github.com/psmux/psmux), plus a Windows-only `~\.psmux.conf`), Windows Terminal, a PowerShell profile — no bash/zsh/iTerm2 |
| DevPod / devcontainer | git, nvim, starship, zsh only (opt-in, see below) |

WSL is treated as the Linux Target — there's no separate WSL handling anywhere in this repo.

## Installing chezmoi

- **macOS**: `brew install chezmoi`
- **Linux**: `sh -c "$(curl -fsLS get.chezmoi.io)"`
- **Windows (PowerShell)**: `iex "&{$(irm 'https://get.chezmoi.io/ps1')}"`

See [chezmoi's install docs](https://www.chezmoi.io/install/) for other options.

## First-time setup on a new machine

```sh
chezmoi init --apply MikesterFH/dotfiles
```

This clones the repo as your Source Dir (to `~/.local/share/chezmoi`, chezmoi's default), prompts you for a few values, and immediately writes the rendered dotfiles into `$HOME`.

To keep the repo somewhere visible instead, clone it yourself and point `init` at it — that clone then *is* the Source Dir, there's no second copy to keep in sync:

```sh
git clone git@github.com:MikesterFH/dotfiles.git ~/dotfiles
chezmoi init --apply --source ~/dotfiles
```

Either way, `.chezmoi.toml.tmpl` writes the clone's path into `~/.config/chezmoi/chezmoi.toml` as `sourceDir`, so every later `chezmoi` command (`apply`, `update`, `cd`, `edit`) uses it without needing `--source` again.

You'll be prompted once for:

- **profile** — which kind of machine this is: `personal`, `dev`, or `dev-server`. Scopes which git identities you're asked for next, and which Applications get installed. Every Profile gets the CLI tools the configs rely on (delta, starship, neovim, tmux, fzf, zoxide, yazi, glow, bat, lazygit); `personal`/`dev` also get the GUI apps (wezterm, VS Code, Zed, Windows Terminal, iTerm2 — whichever apply to your OS), `dev-server` gets none of those. There's no per-app prompt or per-machine override; a machine needing a different app set needs a distinct profile. See `docs/adr/0004-machine-profiles.md`, `docs/adr/0006-application-category-and-profile-manifests.md` and `docs/adr/0008-cli-tools-are-applications.md` for the full rationale.
- **git identity** — name + email for the git contexts your `profile` uses: `personal`+`work` for `personal`, `work`+`client` for `dev`, `personal`+`work` for `dev-server`. These generate `~/.config/git/config.local.{personal,work,client}` (only the ones your profile needs), which the tracked `~/.config/git/config` switches between automatically via `includeIf`, based on which directory you're in (`~/dev/personal/`, `~/dev/work/`, `~/dev/client/`).
- **DevPod/devcontainer?** — answer `false` on a real machine (the default). See below for when to answer `true`.

After the prompts, a `run_once_` script installs the prerequisite Bootstrap Packages (`git`, `mise`, plus Homebrew itself on macOS if it isn't already present; `git`, `mise`, and [`psmux`](https://github.com/psmux/psmux) on Windows) via your platform's package manager (`brew`/`apt`/`dnf`/`pacman` on macOS/Linux, `winget` on Windows) before the rest of the configs are applied. Docker isn't installed by this workflow on any Target — set it up by hand if you need it.

On the macOS Target, once Bootstrap and the rest of the Managed Files have run, a `run_onchange_after_` script installs your Profile's Applications (the CLI tools as `brew` formulae; wezterm, VS Code, Zed, iTerm2 as casks) via `brew bundle` against a Homebrew manifest rendered to `~/.config/homebrew/Brewfile`. Since it's `run_onchange_`, editing the Application list and re-running `chezmoi apply` picks up newly-added apps on an already-provisioned machine too, not just on a fresh install.

On the Linux Target, when the distro is Debian-family (Debian, Ubuntu, Pop!\_OS, Linux Mint, elementary OS — matching Bootstrap's own distro detection; no Fedora/Arch Application manifest yet), the same pattern installs your Profile's Applications (the CLI tools; wezterm, VS Code, Zed) via `apt-get install` against a package list rendered to `~/.config/apt-packages.txt`. Packages your release doesn't ship (older Debian/Ubuntu lack starship, yazi, glow, lazygit) are skipped and listed as a warning — install those by hand.

On the Windows Target, the same pattern installs your Profile's Applications (the CLI tools except tmux, which psmux replaces; wezterm, VS Code, Zed, Windows Terminal) via `winget import` against a manifest rendered to `~/.config/winget/packages.json`.

After the Applications, two more `run_onchange_after_` scripts install the plugin layers: tpm and the `@plugin`s from `tmux.conf` into `~/.config/tmux/plugins` (macOS/Linux), and the Yazi plugins pinned in `package.toml` via `ya pkg install` (every OS). Each reruns when its config file changes. See `docs/adr/0008-cli-tools-are-applications.md`.

If you'd rather review what would happen before anything touches your `$HOME`, run `chezmoi init MikesterFH/dotfiles` (no `--apply`) followed by `chezmoi diff`, then `chezmoi apply` once you're happy with it.

### DevPod / devcontainer

Inside a DevPod container or devcontainer, answer the `devpod` prompt with `true` (or run `chezmoi init --promptBool devpod=true --apply MikesterFH/dotfiles`). This narrows the managed set down to `git`, `nvim`, `starship`, and `zsh` — no GUI-app configs, no tmux — matching what a container actually needs.

## Making changes afterward

Don't edit the deployed files in `$HOME` directly — edit the Source Dir (this repo) and re-apply:

```sh
chezmoi edit ~/.bashrc     # opens the Source Dir file for the given target path
chezmoi diff               # preview what would change
chezmoi apply               # write the change into $HOME
```

Every managed file is **copied**, not symlinked — editing the deployed copy in `$HOME` directly won't do anything on the next `chezmoi apply`, and won't feed back into this repo. This is deliberate (see `docs/adr/0003-copy-apply-not-live-symlinks.md`), mainly because native Windows symlinks need admin rights/Developer Mode.

### Pulling changes on another machine

```sh
chezmoi update             # git pull in the Source Dir, then apply
```

If chezmoi warns `config file template has changed, run chezmoi init to regenerate config file`, run `chezmoi init` (it re-renders `~/.config/chezmoi/chezmoi.toml` from `.chezmoi.toml.tmpl` without asking again for answers it already has), then `chezmoi apply`. Skipping it leaves derived data stale — notably the Profile's Application list, so newly added Applications aren't installed.

### Neovim and psmux on Windows

`home/dot_config/nvim` is the canonical Neovim configuration, including `lazy-lock.json`.
On Windows, `home/.chezmoiscripts/windows/run_after_copy-nvim-windows.ps1.tmpl` mirrors its applied copy to
`AppData\Local\nvim`. Make future changes in the Source Dir rather than only in
that local copy.

`dot_psmux.conf` deploys to `~\.psmux.conf` on native Windows only (not WSL or
DevPod). psmux reads it before the legacy `~\.tmux.conf`, which is left untouched.
It preserves the `Ctrl+f` prefix, Neovim-aware `Ctrl+h/j/k/l` navigation, network
status and clock, without the battery plugin or vim-navigator background poller.
Reload it with `Ctrl+f`, then `r`. The conditional navigation requires psmux 3.4+.
PPM and the declared plugins must already be installed under `~\.psmux\plugins`;
plugin scripts that invoke `pwsh` require PowerShell 7.

### Yazi previews

Markdown is rendered with Glow; text and code use bat with syntax highlighting
and line numbers. Both run through the Piper plugin. Other previewers remain
unchanged. The configuration and pinned `package.toml` are deployed to
`~/.config/yazi` on every platform; on Windows the `run_after_set-yazi-env-windows`
script sets `YAZI_CONFIG_HOME` to that path instead of Yazi's default
`AppData\Roaming\yazi\config`.

`glow` and `bat` are installed as Applications, and `ya pkg install` runs
on apply whenever `package.toml` changes. Debian/Ubuntu name the bat
executable `batcat`; make it available as `bat` on your PATH for these rules.

Yazi needs `file` for MIME detection, and Piper needs `sh`. On Windows the same
script also sets `YAZI_FILE_ONE` to Git for Windows' `usr\bin\file.exe`
and adds Git's `bin` directory to your user PATH for `sh.exe`. Restart your
terminal after the first apply so Yazi inherits the updated environment.

## Repo layout

```
.chezmoiroot          # contains "home": chezmoi reads its Source State from home/
home/                 # mirrors $HOME
  dot_*, private_*, *.tmpl, AppData/, Library/, Documents/
  .chezmoiignore      # per OS / Profile / DevPod: what actually gets deployed
  .chezmoi.toml.tmpl  # the init prompts described above
  .chezmoitemplates/  # shared template partials (VS Code/zed settings reused across OS paths)
  .chezmoiscripts/    # run_* scripts, grouped by OS; creates no directory in $HOME
    unix/  darwin/  linux/  windows/
docs/  .github/       # ADRs, agent docs, CI
```

- `dot_*`, `private_*`, `run_once_*`, `*.tmpl` — chezmoi-managed files, named per [chezmoi's attribute convention](https://www.chezmoi.io/reference/target-types/). `AppData/`, `Library/`, `Documents/` are real (non-`dot_`) directory names — chezmoi applies literal names as-is.
- The subfolders of `.chezmoiscripts/` are only for orientation: each script still guards itself with an OS check in its template, so the folder name alone doesn't decide where it runs.
- `.github/workflows/ci.yml` — a 3-OS matrix (macOS/Linux/Windows) that applies this repo to a throwaway directory and asserts the Target-specific file set is correct on every push/PR.

## Existing config on a machine

**On a brand-new machine with no prior dotfiles setup, you don't need to do anything extra** — `chezmoi apply` only ever writes to the specific paths this repo manages, and there's nothing there to lose.

**If you have existing config at any of the paths this repo manages** — hand-written files, or symlinks left by this repo's old pre-chezmoi `install.sh` — `chezmoi apply` will silently overwrite them; chezmoi does not prompt per-file. Run `chezmoi init MikesterFH/dotfiles` (without `--apply`) and `chezmoi diff` first to see exactly what would be overwritten, back up anything you'd miss, then `chezmoi apply`. Old `install.sh` symlinks are simply replaced by real files.
