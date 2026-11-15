# 0024: GlazeWM and Zebar as the Windows tiling window manager

**Context:** ADR 0018 gave macOS a tiling window manager (AeroSpace); Windows had none. GlazeWM tiles like i3, is configured by one YAML file, and ships on winget. It has no bar of its own: its authors' companion, Zebar, draws a status bar from HTML widgets and reads GlazeWM's workspaces. Both look for their config under `~/.glzr`.

**Decision:**
- `glazewm` and `zebar` are GUI Applications on personal and dev, Windows only (winget `glzr-io.glazewm` and `glzr-io.zebar`, no brew, apt or nix identifier). Their configs live at `.glzr/glazewm/config.yaml` and `.glzr/zebar/settings.json`, excluded on every other OS and when the Application is absent for the Profile.
- GlazeWM owns Zebar's lifetime: its `startup_commands` launch Zebar and its `shutdown_commands` stop it. Zebar's `settings.json` opens the `with-glazewm` widget of the built-in `glzr-io.starter` pack, so no widget pack is vendored here.
- The bindings mirror AeroSpace's (same letters, digits and modes) on `lctrl+lalt` instead of ⌃⌥. Only the left keys: Windows reports AltGr as ctrl+right-alt, and on the Swiss German layout AltGr types `@ # | [ ] { }`, which a generic `ctrl+alt` binding would swallow.

**Consequences:** AeroSpace features without a GlazeWM command are left out (accordion layout, balance-sizes, flatten, join-with, close-all-but-current); `lctrl+lalt+shift+tab` moves the workspace to the monitor on the right without wrapping. The outer top gap leaves room for Zebar's 40px bar, so changing the bar's height means changing both files. Zebar rewrites `settings.json` when a widget is toggled in its tray menu; the next `chezmoi apply` resets that, so startup widgets change in the Source Dir. Starting GlazeWM at login is a tray setting ("Run on system startup"), a one-time manual step this repo doesn't manage. There is no Windows counterpart to the Raycast cheat sheet.
