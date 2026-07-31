# Dotfiles

Personal configuration for macOS, Linux (incl. WSL), and native Windows, deployed and kept in sync via chezmoi.

## Language

**Source Dir**:
This repo itself — chezmoi's source-of-truth directory, laid out to mirror `$HOME` (e.g. `dot_bashrc` → `~/.bashrc`).
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
A prerequisite tool (`git`, `mise`) installed once per machine via the platform's package manager (winget on the Windows Target) before `chezmoi apply` can do anything useful.
_Avoid_: dependency, tool install

**Profile**:
A `chezmoi init` prompt (`personal` | `dev` | `dev-server`) scoping which git identities and GUI configs a given physical machine gets, orthogonal to the Target and to `devpod`. See `docs/adr/0004-machine-profiles.md`.
_Avoid_: environment, mode, setup type
