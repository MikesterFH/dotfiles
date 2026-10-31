# 0022: WezTerm defaults to WSL on Windows

**Context:** ADR 0015 made PowerShell 7 WezTerm's default and only shell on Windows. Day-to-day work on Windows machines happens in WSL, so every new tab needed a detour through the launcher. WezTerm starts through the `persistent` unix domain (`default_gui_startup_args`), and its `wezterm-mux-server` only knows the local domain: `default_domain` pointing at a WSL domain is ignored there, and the tab falls back to `default_prog`.

**Decision:**
- On Windows, WezTerm's `default_prog` is `wsl.exe -d <distro> --cd ~` when a WSL distribution exists (the first from `wezterm.default_wsl_domains()`, or `WEZTERM_WSL_DISTRO`). It is launched as a local program, not via a WSL domain, so it works through the mux server.
- Without WSL, the default stays PowerShell 7 (`pwsh.exe`), and falls back to Windows PowerShell 5.1 (`powershell.exe`) when `pwsh.exe` is not on `PATH`.
- The launcher (`<leader>t`, or right-click on the new-tab button) lists PowerShell, Git Bash (if found) and WSL.
- `.bashrc` puts `~/.local/bin` and `~/.opencode/bin` on `PATH` before activating mise. A WSL login shell reads `~/.bash_profile` instead of `~/.profile` once an installer (bun, cargo) has created it, which left mise, and with it every mise-installed CLI tool, off `PATH`.

**Consequences:** supersedes the WezTerm part of ADR 0015; Windows Terminal is unchanged. WSL tabs start the distribution's login shell, which runs the managed `.bashrc` (or `.zshrc` after `chsh`). `~/.bash_profile` stays unmanaged, since installers append to it.
