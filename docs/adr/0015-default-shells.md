# 0015: Default shells: zsh with oh-my-zsh on Unix, PowerShell 7 on Windows

**Context:** `.zshrc` loads oh-my-zsh only if `~/.oh-my-zsh` exists, and nothing installed it, so the git plugin's aliases existed only where it had been cloned by hand. On Linux zsh itself wasn't installed. On Windows the managed PowerShell profile (mise, starship, aliases) lives in `Documents\PowerShell`, which only PowerShell 7 (`pwsh`, a Bootstrap Package) reads, yet WezTerm launched Windows PowerShell 5.1 (`powershell.exe`) and Windows Terminal defaulted to Git Bash. Neither got mise, so neither found the mise-installed Neovim (ADR 0013).

**Decision:**
- zsh is an Application installed through apt on Linux (macOS ships it). oh-my-zsh comes from a chezmoi `git-repo` external on macOS and Linux: chezmoi clones it once and `git pull --ff-only`s it weekly, so an existing clone and its `custom/` directory are left alone. `.zshrc` turns oh-my-zsh's own updater off and sets no theme, since chezmoi updates it and starship draws the prompt.
- On Windows, PowerShell 7 is the default shell: WezTerm's `default_prog` and only launch menu entry is `pwsh.exe`, and Windows Terminal's default profile is the PowerShell 7 profile, with Git Bash hidden.
- Git for Windows (`Git.Git`) stays a Bootstrap Package. It ships Git Bash, but it is needed regardless: for `git` itself, and for the `file.exe` and `sh.exe` yazi runs (ADR 0014). Git Bash simply isn't offered as a shell any more.

**Consequences:** every terminal on every Target starts a shell that activates mise and finds Neovim. Changing the login shell to zsh on Linux (`chsh`) stays a manual step, because it needs the user's password. Git Bash is still installed on Windows and can be unhidden in Windows Terminal; nothing in the repo depends on it as a shell. Windows PowerShell 5.1 remains available but unmanaged.

**Update (ADR 0020):** the profile now lives at `~\.config\powershell\profile.ps1`; both `Documents\PowerShell` and `Documents\WindowsPowerShell` get a stub that dot-sources it, so 5.1 also activates mise (without the chpwd hook).
