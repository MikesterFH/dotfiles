# chezmoi replaces install.sh and install-devpod-dotfiles.sh entirely

`install.sh` (794 lines) and `install-devpod-dotfiles.sh` (207 lines) hand-roll OS detection, package bootstrap, and Stow-like symlinking for macOS/Linux/WSL, with no native Windows path. We're replacing both scripts entirely with chezmoi as the single installation mechanism across all three targets (macOS, Linux/WSL, native Windows), rather than extending the bash scripts with a Windows branch.

Hand-written bash can't run natively on Windows, and every platform edge case (OS-conditional file content, per-machine prompts, package manager differences) would have to be re-implemented by hand. chezmoi already solves templating, OS-conditional files, and prompted data as a maintained tool — extending our own script would mean building a worse version of it.
