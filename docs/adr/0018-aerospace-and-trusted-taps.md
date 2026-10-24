# 0018: AeroSpace as the macOS tiling window manager, from a trusted tap

**Context:** macOS has no built-in tiling. Of the options, yabai needs System Integrity Protection partly disabled to manage Spaces, Amethyst builds on the slow native Spaces, and Rectangle and Raycast only snap windows. AeroSpace tiles like i3, emulates its own workspaces without touching SIP, and is configured by one TOML file. It isn't in homebrew-core: it ships only from its author's tap, `nikitabobko/tap`, and Homebrew now refuses to load casks from a tap nobody has trusted.

**Decision:**
- `aerospace` is a GUI Application on personal and dev, macOS only (no winget or apt identifier). Its config lives at `.config/aerospace/aerospace.toml`, excluded on every other OS.
- The Brewfile template gets a `$homebrewTaps` map, so a cask from a third-party tap emits a `tap` line first. The line trusts only the casks taken from that tap (`trusted: { casks: ["aerospace"] }`), not the whole tap, so anything else added to it later still needs an explicit decision.
- The bindings use ctrl-alt instead of AeroSpace's default alt. On the Swiss German layout ⌥ types characters (`@ [ ] | { }`), and Neovim uses `<M-h/j/k/l>` to resize splits.

**Consequences:** AeroSpace starts at login and owns window placement; Rectangle's window shortcuts are already empty and its remaining ⌃⌥N/⌃⌥B todo bindings stay free. Bindings are named by US-qwerty key positions, so only letters, digits and tab are bound. AeroSpace works best with Mission Control's "Displays have separate Spaces" turned off, a system setting this repo doesn't manage.
