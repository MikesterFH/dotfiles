# 0025: Keyboard firmware lives in the dotfiles

**Context:** The Corne keyboard runs ZMK, configured in its own repo (`corne-wireless-view-zmk-config`). Its window-manager layer (hold TAB) sends every key with the WM modifier, and the WM configs here (AeroSpace, ADR 0018; GlazeWM, ADR 0024) bind exactly those combinations. A change to one side almost always needs the other (the AeroSpace resize mode gained `ctrl-alt` keys for the layer), but two repos meant two commits and two PRs with nothing keeping them in step. A submodule would only add a pointer bump on top.

**Decision:**
- The keymap repo is imported with `git subtree` (history kept) into `keyboard/`. It sits outside `home/`, so chezmoi never deploys it.
- `keyboard/` is itself the ZMK config directory (`.keymap`, `.conf`, `west.yml`, `build.yaml`). ZMK's reusable build workflow copies `config_path` with a plain `mkdir`, so the directory must be one level deep and must not be called `zmk` (west checks ZMK out as `zmk/`). `west.yml`'s `self.path` is `keyboard` to match.
- `.github/workflows/keyboard.yml` builds the firmware only when `keyboard/**` or the workflow changes. It pins ZMK's reusable workflow to the same commit as `west.yml`. The chezmoi verification workflow (`ci.yml`) ignores pushes that touch only `keyboard/` or `keyboard.yml`.
- Any config that binds shortcuts is checked against the keymap, and both sides change in one commit (rule in `AGENTS.md`, "Keyboard shortcuts").
- The old keymap repo is archived with a pointer here.

**Consequences:** A keymap change and the matching WM config change land in one commit. Firmware builds appear in this repo's Actions tab; flashing is unchanged (`keyboard/README.md`). Bumping ZMK means changing the pin in both `keyboard/west.yml` and `keyboard.yml`.
