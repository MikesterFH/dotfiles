# Dotfiles

Personal configuration for macOS, Linux (incl. WSL), and native Windows, deployed and kept in sync via chezmoi.

## Language

**Source Dir**:
This repo itself — chezmoi's source-of-truth directory. Its `home/` folder (chosen via `.chezmoiroot`) mirrors `$HOME` (e.g. `home/dot_bashrc` → `~/.bashrc`); repo meta (docs, CI, helper scripts) lives beside it.
_Avoid_: dotfiles folder, source tree, repo root

**Target State**:
The desired content chezmoi computes from the Source Dir and writes into `$HOME` when you run `chezmoi apply`.
_Avoid_: destination, output, applied state

**Managed File**:
A file chezmoi copies from the Source Dir into the Target State. The default for every file in this repo — not a symlink.
_Avoid_: symlinked file, linked config

**Windows Target**:
Native Windows (PowerShell), one of the three deployment targets. WSL is classified as the Linux Target, not the Windows Target — it gets no separate handling.
_Avoid_: Windows (ambiguous alone), WSL Target

**Bootstrap Package**:
A prerequisite tool — `git`, `mise`, and the platform's own package manager where it isn't preinstalled (Homebrew on the macOS Target; apt and winget already ship with their OS) — installed once per machine via `run_once_before_install-packages.*`, profile-independent. Strictly what chezmoi/dev work needs before anything else can run, not "software I always want" (that's an Application).
_Avoid_: dependency, tool install, Application (see below)

**Application**:
Software a machine needs beyond the Bootstrap Package minimum — CLI tools the configs rely on (delta, starship, tmux, yazi, …; the same on every Profile) and GUI apps (e.g. wezterm, VS Code, Zed; per Profile) alike — installed via a package-manager-native manifest (`Brewfile`, `apt-packages.txt`, a winget manifest; one file per platform, each carrying its own package identifier per app) rendered from the machine's Profile. Manifests run via `run_onchange_`, so editing the app list reaches already-provisioned machines on their next `chezmoi apply`. See `docs/adr/0006-application-category-and-profile-manifests.md` and `docs/adr/0008-cli-tools-are-applications.md`.
_Avoid_: package, tool (when meaning this specifically), Bootstrap Package (see above)

**Profile**:
A `chezmoi init` prompt (`personal` | `dev` | `dev-server`) scoping which git identities, GUI configs, and Applications a given physical machine gets, orthogonal to the Target and to `devpod`. Deviation within a Profile isn't supported — two machines needing different Applications need two distinct Profiles (e.g. `personal-laptop`, `personal-desktop`), not a per-machine override. See `docs/adr/0004-machine-profiles.md` and `docs/adr/0006-application-category-and-profile-manifests.md`.
_Avoid_: environment, mode, setup type
