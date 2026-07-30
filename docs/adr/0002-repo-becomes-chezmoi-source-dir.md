# This repo becomes the chezmoi Source Dir directly

chezmoi expects its Source Dir to mirror `$HOME` (`dot_bashrc` → `~/.bashrc`); this repo instead groups files by tool (`bash/`, `nvim/`, `git/`, ...). We're restructuring the repo itself into chezmoi's expected layout — renaming every managed file to chezmoi's naming convention — rather than keeping the tool-folder layout and writing a translation wrapper that copies or symlinks into a separate chezmoi source directory.

Fighting chezmoi's expected layout would mean maintaining a permanent translation layer that every future chezmoi feature (OS-conditional ignores, `run_once_` scripts, templating) has to go through. One canonical layout is simpler to reason about long-term, even though the rename touches every file in the repo and is expensive to undo.
