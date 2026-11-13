# dotfiles

chezmoi Source Dir for macOS, Linux/WSL and native Windows. `.chezmoiroot` points chezmoi at `home/`, which mirrors `$HOME` in chezmoi's naming (`dot_`, `private_`, `empty_`, `create_`, `.tmpl`). Everything outside `home/` is repo meta (docs, CI) and never deploys. Vocabulary (Source Dir, Target, Profile, Application, Bootstrap Package) lives in `CONTEXT.md`; use those terms.

## Workflow

- Change config in `home/`, then `chezmoi apply`. The chezmoi config's `sourceDir` points at this clone, so no `--source` is needed and there is no second copy to sync.
- Deployed files in `$HOME` are copies: a direct edit there is overwritten by the next apply. Carry live edits back into `home/` before applying.
- After changing `home/.chezmoi.toml.tmpl`, run `chezmoi init` before `chezmoi apply`; otherwise derived data (the Application list) stays stale.
- Shared VS Code / Zed settings live once in `home/.chezmoitemplates/` and are included by the per-OS paths (`dot_config/`, `Library/`, `AppData/`).

## Verifying a change without touching `$HOME`

Render every Profile into a scratch dir and run the CI asserts, the same seam CI uses:

```sh
tmp=$(mktemp -d)
for p in personal dev dev-server; do
  mkdir -p "$tmp/dest-$p"
  chezmoi execute-template --init --config .github/scripts/ci-answers/$p.toml --source . < home/.chezmoi.toml.tmpl > "$tmp/cfg-$p.toml"
  chezmoi apply --config "$tmp/cfg-$p.toml" --source . --destination "$tmp/dest-$p" \
    --exclude scripts --persistent-state "$tmp/state-$p.boltdb" --force
  .github/scripts/assert-unix.sh "$tmp/dest-$p" "$p"
done
```

Other OSes: render a single template with `--override-data '{"chezmoi":{"os":"windows"}}'`. CI (`.github/workflows/ci.yml`) runs the asserts on macOS, Linux and Windows for every push; it checks the rendered file tree, never script side effects.

## Conventions that bite

- **Applications** (ADR 0006, 0023): declared once in `home/.chezmoidata/applications.toml` (fields documented in its header); adding, removing or re-sourcing one is an edit there. A change to a `mise` entry also needs `home/dot_config/mise/mise.lock` regenerated (`.github/scripts/mise-lock.sh`, never on a NixOS host: its mise compiles python and locks a NixOS-only entry), or `mise install --locked` fails on every Target; `mise-lock.sh --check` verifies it. Entry order is manifest line order. The config template `.chezmoi.toml.tmpl` cannot read `.chezmoidata`, so every consumer filters by Profile itself through `includeTemplate "applications.json"` / `"application-names.json"` (`home/.chezmoitemplates/`). The asserts read their expected IDs from the same file and add fixed spot checks; a GUI app's config is excluded in `home/.chezmoiignore` when the app is absent for the Profile.
- **Nix module** (ADR 0021): `nix/home-module.nix` still carries its own package list (until #31). When `applications.toml` changes, update it too. Verify by building a consumer's home-manager config against this clone (`--override-input dotfiles path:$PWD`).
- **Neovim version** is pinned via `version` on `neovim` and `tree-sitter-cli` in `applications.toml`, installed by mise on every OS, because `nvim/lazy-lock.json` only fits one Neovim (ADR 0013). To update: raise the pin, `chezmoi apply`, `:Lazy update` + `:TSUpdate`, check nvim starts clean, copy the new `~/.config/nvim/lazy-lock.json` back into `home/`, commit pin and lockfile together.
- **Scripts** live in `home/.chezmoiscripts/{unix,darwin,linux,windows}/`. The folder is orientation only: every script carries its own OS guard (plus `devpod` where relevant) in its template. They run in target-name order, so `darwin/`/`linux/` installs precede `unix/` ones. A `run_onchange_` script reruns when its rendered content changes, so it embeds a hash of whatever should trigger it (`{{ includeTemplate "…" . | sha256sum }}` or `{{ include "…" | sha256sum }}`).
- **`.chezmoiignore`** has a per-OS switch where each branch lists everything *not* for that OS. The catch-all skip list at its bottom is mirrored in both assert scripts; change all three together.
- **Line endings**: LF everywhere (`.gitattributes`); the deployed git config sets `autocrlf` per Target.
- **Decisions** that change how the repo works get an ADR in `docs/adr/` (next number, short prose: context, decision, consequences). Flag it when a change contradicts an existing ADR.
- **Commits**: subject `dotfiles: <what changed>` (`docs:` for docs-only), body explains why. The message ends with the body: no `Co-Authored-By:`, `Generated with`, or other agent attribution/trailer lines, regardless of tool defaults (the global `commit-msg` hook strips them anyway, ADR 0009).

## Agent skills

### Issue tracker

Issues tracked as GitHub Issues in `MikesterFH/dotfiles`, via `gh` CLI. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.
