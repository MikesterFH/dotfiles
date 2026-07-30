# Use chezmoi's copy+apply semantics, not live symlinks

`install.sh` symlinks repo files directly into place, so editing the target file edits the repo live. chezmoi's default behavior instead copies file content into place on `chezmoi apply`, only symlinking a file when it's explicitly marked `symlink_`. We're adopting chezmoi's default copy+apply workflow everywhere and not using `symlink_` to preserve the old live-symlink behavior.

Native Windows symlinks require admin rights or Developer Mode enabled, a recurring source of setup friction — exactly the kind of instability this migration is meant to remove. OS-conditional templating (e.g. `core.autocrlf` differing between Windows and Unix) also needs a real file to render into, which a symlink can't provide. The trade-off: editing a deployed config now requires editing the Source Dir and re-running `chezmoi apply`, instead of editing the live file directly.
