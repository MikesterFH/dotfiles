# 0010: Neovim spell files as chezmoi externals

**Context:** `options.lua` sets `spelllang = { "de", "en" }`. Neovim ships only the English word list; for any other language it offers to download the file through its spellfile plugin, which runs on netrw. LazyVim's `disabled_plugins` turns netrw off, so on every machine that never had the file the prompt silently never comes and each start warns `Cannot find word list "de.utf-8.spl"`. The file was present only on the machine where the setting was written.

**Decision:** `home/.chezmoiexternal.toml.tmpl` downloads `de.utf-8.spl` and `de.utf-8.sug` from the Vim runtime mirror into Neovim's data dir (`~/.local/share/nvim/site/spell`, on Windows `AppData/Local/nvim-data/site/spell`) whenever `neovim` is in the Application list. It is the repo's first chezmoi external; binary third-party files go there rather than being committed.

**Consequences:** `chezmoi apply` needs network access the first time and then every 90 days (`refreshPeriod`). A new spell language means adding its file names to the external template. Because chezmoi now owns `~/.local/share` as a parent dir, the Source Dir carries `private_dot_local/private_share/.keep` so apply keeps those dirs at 0700 instead of loosening them to 0755; Windows ignores `.local`. The CI asserts render with externals too, so they check that both files land in the data dir.
