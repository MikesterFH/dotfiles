# 0020: PowerShell profile at a fixed path, loaded through a stub

**Context:** chezmoi deployed the PowerShell profile to `~\Documents\PowerShell`, but PowerShell reads it from the real Documents folder, which OneDrive folder redirection can move (e.g. `~\OneDrive - <Org>\Documents`). A `run_after` script copied the file there after every apply, leaving two copies, one of them outside chezmoi's view. Windows PowerShell 5.1 reads `Documents\WindowsPowerShell` and got no profile at all. chezmoi also runs `.ps1` scripts through `powershell.exe` with the user's profile, so every script loaded mise and starship.

**Decision:**
- The managed profile lives at the fixed Target `~\.config\powershell\profile.ps1`.
- `run_after_link-powershell-profile-windows.ps1` writes a one-line stub (`. "<path to profile.ps1>"`) into `PowerShell\` and `WindowsPowerShell\` under the resolved Documents folder, rewriting it only when it differs.
- The profile silences mise's chpwd warning on 5.1; 5.1 still gets the PATH from `mise activate`.
- chezmoi's `ps1` interpreter runs with `-NoLogo -NoProfile`.

**Consequences:** one real copy of the profile, managed by chezmoi, independent of OneDrive. The stub is a reference rather than a copy, an intentional exception to ADR 0003 that needs no symlink rights. Its content is a plain file outside chezmoi's state, so deleting the profile from the repo leaves stale stubs behind. Scripts no longer inherit profile side effects.
