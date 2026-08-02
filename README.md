# dotfiles

Personal configuration for macOS, Linux (including WSL), and native Windows, deployed and kept in sync via [chezmoi](https://www.chezmoi.io/).

This repo *is* chezmoi's **Source Dir** — it's laid out to mirror `$HOME` using chezmoi's naming convention (e.g. `dot_bashrc` → `~/.bashrc`), not to be cloned and used directly. See `CONTEXT.md` for the vocabulary used throughout this repo and `docs/adr/` for the reasoning behind the bigger decisions (why chezmoi, why this repo is the Source Dir, why copy+apply instead of live symlinks).

## Supported Targets

| Target | What gets deployed |
| --- | --- |
| macOS | bash, zsh, tmux, git, starship, wezterm, VS Code, nvim, zed, iTerm2 |
| Linux / WSL | same as macOS, minus iTerm2 |
| Native Windows | git, starship, wezterm, VS Code, nvim, zed, tmux (via [psmux](https://github.com/psmux/psmux)), Windows Terminal, a PowerShell profile — no bash/zsh/iTerm2 |
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

This clones the repo as your Source Dir, prompts you for a few values, and immediately writes the rendered dotfiles into `$HOME`.

You'll be prompted once for:

- **profile** — which kind of machine this is: `personal`, `dev`, or `dev-server`. Scopes which git identities you're asked for next, and which Applications (wezterm, VS Code, Zed, Windows Terminal, iTerm2) get deployed — `personal`/`dev` get all of them (whichever apply to your OS), `dev-server` gets none. There's no per-app prompt or per-machine override; a machine needing a different app set needs a distinct profile. See `docs/adr/0004-machine-profiles.md` and `docs/adr/0006-application-category-and-profile-manifests.md` for the full rationale.
- **git identity** — name + email for the git contexts your `profile` uses: `personal`+`work` for `personal`, `work`+`client` for `dev`, `personal`+`work` for `dev-server`. These generate `~/.config/git/config.local.{personal,work,client}` (only the ones your profile needs), which the tracked `~/.config/git/config` switches between automatically via `includeIf`, based on which directory you're in (`~/dev/personal/`, `~/dev/work/`, `~/dev/client/`).
- **DevPod/devcontainer?** — answer `false` on a real machine (the default). See below for when to answer `true`.

After the prompts, a `run_once_` script installs the prerequisite Bootstrap Packages (`git`, `mise`, and Docker on macOS/Linux, plus Homebrew itself on macOS if it isn't already present; `git`, `mise`, and [`psmux`](https://github.com/psmux/psmux) on Windows) via your platform's package manager (`brew`/`apt`/`dnf`/`pacman` on macOS/Linux, `winget` on Windows) before the rest of the configs are applied.

On the macOS Target, once Bootstrap and the rest of the Managed Files have run, a `run_onchange_after_` script installs your Profile's Applications (wezterm, VS Code, Zed, iTerm2 — whichever apply to macOS) via `brew bundle` against a Homebrew manifest rendered to `~/.config/homebrew/Brewfile`. Since it's `run_onchange_`, editing the Application list and re-running `chezmoi apply` picks up newly-added apps on an already-provisioned machine too, not just on a fresh install. Linux and Windows Application manifests aren't implemented yet.

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

## Repo layout

- `dot_*`, `private_*`, `run_once_*`, `*.tmpl` — chezmoi-managed files, named per [chezmoi's attribute convention](https://www.chezmoi.io/reference/target-types/). `AppData/`, `Library/`, `Documents/` at the repo root are real (non-`dot_`) directory names — chezmoi applies literal names as-is.
- `.chezmoiignore` — the single place that decides, per OS (and per the DevPod flag), which of the above actually gets deployed.
- `.chezmoi.toml.tmpl` — the prompts described above.
- `.chezmoitemplates/` — shared template partials (e.g. VS Code/zed settings reused across OS-specific target paths).
- `migrate-from-install-sh.sh` — one-time cutover helper, see below. Not part of the regular chezmoi flow.
- `.github/workflows/ci.yml` — a 3-OS matrix (macOS/Linux/Windows) that applies this repo to a throwaway directory and asserts the Target-specific file set is correct on every push/PR.

## Backing up / migrating an existing machine

**On a brand-new machine with no prior dotfiles setup, you don't need to do anything extra** — `chezmoi apply` only ever writes to the specific paths this repo manages, and there's nothing there to lose.

**If this machine previously used this repo's old `install.sh`** (a plain bash script that used to symlink files into place, before the chezmoi migration), run the one-time migration script *first*, before your first `chezmoi init --apply`:

```sh
./migrate-from-install-sh.sh
```

It walks every path `install.sh` could have symlinked and, per path:

- removes the symlink if it points back into this repo's old (pre-chezmoi) layout,
- **backs up** (renames with a timestamped `.dotfiles-migration-bak.<timestamp>` suffix — never deletes) any real file it finds instead,
- leaves alone and reports any symlink pointing somewhere else entirely,
- does nothing if there's nothing at that path.

It's safe to run on a machine that never used `install.sh` at all — everything will simply be reported as already absent.

**If you have unrelated, hand-written config at any of the paths this repo manages** (not from `install.sh`, not from chezmoi) — `chezmoi apply` will silently overwrite it, chezmoi does not prompt per-file. Back up anything you'd miss yourself before your first apply, or run `chezmoi init` (without `--apply`) and `chezmoi diff` first to see exactly what would be overwritten.
