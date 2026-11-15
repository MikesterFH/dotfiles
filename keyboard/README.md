# Corne Wireless (nice!view) – ZMK Config

ZMK firmware configuration for a Typeractive Corne Wireless (nice!nano v2 + nice!view)
used with the **Swiss German (CH-DE) OS layout** on **Windows and macOS**.

- ZMK documentation: <https://zmk.dev/docs>
- Typeractive firmware guide: <https://docs.typeractive.xyz/build-guides/corne-wireless/firmware>

## 1. Architecture

### Repository layout

```
.github/workflows/build.yml   CI: builds firmware via ZMK's reusable workflow on every push
build.yaml                    Build matrix: board + shields per keyboard half
config/west.yml               ZMK version (pinned commit)
config/corne.conf             Kconfig options (BT TX power, debounce, sleep)
config/corne.keymap           The keymap: defines, macros, conditional layers, layers
```

### Key concept: ZMK sends positions, not characters

ZMK sends **HID key codes**, which are named after the **US layout**. The OS turns them into
characters using its active layout. With CH-DE active, `&kp AT` (US `Shift+2`) prints `"`, not `@`.

That is why `corne.keymap` defines every symbol as the key combination that produces it on CH-DE,
e.g. `@` is `AltGr+2` on Windows and `Option+G` on macOS:

```c
#define WIN_AT   RA(N2)      // @  (AltGr = right Alt)
#define MAC_AT   RA(G)       // @  (right Option)
```

The prefixes in `corne.keymap`:

| Prefix | Meaning |
|---|---|
| `CH_*`  | Same combination on Windows and macOS (Shift-based, umlauts) |
| `WIN_*` | Windows CH-DE, via AltGr (`RA(...)`) |
| `MAC_*` | macOS Swiss German, via **right** Option (`RA(...)`) |

### Layer stack

| # | Define | Display name | Activated by |
|---|---|---|---|
| 0 | `BASE`      | Win       | always (default layer) |
| 1 | `LOWER`     | Lower     | hold left thumb `LWR` |
| 2 | `RAISE_WIN` | Raise Win | hold right thumb `RSE` (Windows mode) |
| 3 | `MAC`       | Mac       | toggle `MAC` in Adjust; overlay that only remaps `RSE` |
| 4 | `RAISE_MAC` | Raise Mac | hold right thumb `RSE` (Mac mode) |
| 5 | `ADJUST`    | Adjust    | hold `LWR` + `RSE` (conditional layer) |
| 6 | `WM_WIN`    | WM Win    | hold `TAB` (Windows mode) |
| 7 | `WM_MAC`    | WM Mac    | hold `TAB` (Mac mode, via `MAC` overlay) |

Data flow when pressing `RSE`:

```
Windows mode:  BASE ──RSE──▶ RAISE_WIN
Mac mode:      BASE + MAC ──RSE──▶ RAISE_MAC   (MAC overlay replaces &mo RAISE_WIN)
Both:          LWR + RSE ──▶ ADJUST            (conditional_layers)

Hold TAB:      Windows mode ──▶ WM_WIN (Alt+key,      GlazeWM)
               Mac mode     ──▶ WM_MAC (Ctrl+Alt+key, AeroSpace)
```

## 2. Usage

### Base (`Win`)

```
|TAB/WM|  Q  |  W  |  E  |  R  |  T  |   |  Z  |  U  |  I  |  O  |  P  | BKSP |
| CTRL |  A  |  S  |  D  |  F  |  G  |   |  H  |  J  |  K  |  L  |  ö  |  ä   |
| SHFT |  Y  |  X  |  C  |  V  |  B  |   |  N  |  M  |  ,  |  .  |  -  | ESC  |
                   | GUI | LWR | SPC |   | ENT | RSE | ALT |
```

### Lower (hold `LWR`)

```
| TAB  |  1  |  2  |  3  |  4  |  5  |   |  6  |  7  |  8  |  9  |  0  | BKSP |
| CTRL |     |     |     |     |     |   | LFT | DWN |  UP | RGT |     |      |
| SHFT |     |     |     |     |     |   | HOME| PGDN| PGUP| END |     |      |
```

### Raise (hold `RSE`) – identical on Windows and macOS

```
| TAB  |  !  |  @  |  #  |  $  |  %  |   |  ^  |  &  |  *  |  (  |  )  | BKSP |
| CTRL |  ü  |  ~  |  `  |  '  |  "  |   |  -  |  =  |  [  |  ]  |  \  | CTRL |
| SHFT |  <  |  >  |  ?  |  €  |  /  |   |  _  |  +  |  {  |  }  |  |  | SHFT |
```

- `^`, `` ` ``, `~` are dead keys on CH-DE; macros (`ch_caret`, `ch_grave`, `win_tilde`,
  `mac_tilde`) send the key followed by `SPACE`, so the character appears immediately.
- Right `CTRL` / `SHFT` (macros `win_rctrl`, `win_rshft`, `mac_rctrl`, `mac_rshft`) switch back
  to the base layer (`&to`) and hold the modifier, so you can type e.g. `Ctrl+C` or a capital
  letter without releasing `RSE`. Left `CTRL` / `SHFT` stay plain modifiers for symbol combos.

### Adjust (hold `LWR` + `RSE`)

```
| BOOT |  F1 |  F2 |  F3 |  F4 |  F5 |   |  F6 |  F7 |  F8 |  F9 | F10 | BOOT |
| BTCLR| BT1 | BT2 | BT3 | BT4 | BT5 |   | PREV| VOL-| VOL+| NEXT| F11 |  F12 |
|      | MAC |     |     |     |     |   | MUTE| PLAY| BRI-| BRI+|     |      |
```

- `MAC`: toggles between Windows (default) and macOS symbols. The nice!view shows `Mac` while active.
  The state is **not persisted**: after a reboot the keyboard starts in Windows mode.
- `BOOT`: puts the half it is pressed on into the bootloader (for flashing).
- `BTCLR` clears the current Bluetooth profile, `BT1`–`BT5` select profiles 0–4.

### WM – window manager (hold `TAB`)

```
| hold |  1  |  2  |  3  |  4  |  5  |   |  6  |  7  |  8  |  9  | TAB |      |
|      |  A  |  S  |     |  F  |  T  |   |  H  |  J  |  K  |  L  |     |      |
| SHFT |     |     |  C  |  R  |     |   |     |     |     |     |     |      |
                   |     |     | SPC |   |     | SHFT|     |
```

- Tapping `TAB` still sends `TAB`; holding it opens the layer (`&lt`, flavor `balanced`, 200 ms).
- Every key sends the OS window-manager modifier plus the key, so both WMs bind the same keys:
  - Windows (GlazeWM): `Alt` – `Ctrl+Alt` is AltGr on Windows and would swallow `@ # |`.
  - macOS (AeroSpace): `Ctrl+Alt` – matches `~/.config/aerospace/aerospace.toml` in the dotfiles.
- `SHFT` (left, or right thumb) adds Shift, i.e. the "move" variant: `TAB` + `SHFT` + `H` = move window
  left, `TAB` + `SHFT` + `3` = move window to workspace 3.
- Unused positions are `&none`, so a stray key in the layer does nothing.

The diagram shows the **key sent**, not the physical key. Physical key (base layer) → action:

| Physical key | Sends (macOS) | AeroSpace | `+ SHFT` |
|---|---|---|---|
| `Q W E R T` | `⌃⌥1`–`⌃⌥5` | workspace 1–5 | move window to workspace 1–5 |
| `Z U I O` | `⌃⌥6`–`⌃⌥9` | workspace 6–9 | move window to workspace 6–9 |
| `P` | `⌃⌥tab` | previous workspace | move workspace to next monitor |
| `A` | `⌃⌥a` | accordion layout (again: flip orientation) | – |
| `S` | `⌃⌥s` | service mode | – |
| `F` | `⌃⌥f` | fullscreen | float / tile window |
| `G` | `⌃⌥t` | tiles layout (again: flip orientation) | – |
| `H J K L` | `⌃⌥h/j/k/l` | focus left/down/up/right | move window left/down/up/right |
| `C` | `⌃⌥c` | Raycast shortcuts cheat sheet | – |
| `V` | `⌃⌥r` | resize mode | – |
| `SPC` | `⌃⌥space` | Raycast | – |

AeroSpace modes, reachable while still holding `TAB`:

- **Resize** (`V`): `H/L` narrower/wider, `J/K` taller/shorter, `V` again (or `esc`) leaves.
  The `ctrl-alt-*` variants live in the dotfiles' `aerospace.toml` resize mode.
- **Service** (`S`), one-shot maintenance, each key returns to normal mode. Not ctrl-alt bound
  yet, so release `TAB` first: `esc` reload config, `r` reset (flatten) the workspace layout,
  `backspace` close all other windows, `Shift+H/J/K/L` join the window with its neighbour into a
  sub-container.
- **Accordion vs. tiles**: tiles places windows side by side; accordion stacks them on top of each
  other, the focused one in front and the others peeking out 30 px at the edge, like tabs.
  Useful on small screens or for many windows in one workspace.

## 3. Configuration – making a change

### Workflow

1. Create a branch: `git checkout -b dev`
2. Edit `config/corne.keymap`:
   - **Change a key:** replace the binding at the same position in the `bindings = < ... >` block
     of the layer. Each layer has 42 positions (3 × 12 + 6 thumbs), in reading order.
   - **New symbol:** add a `#define` with the CH-DE combination. Use `CH_*` if it is the same on
     both systems, otherwise add a `WIN_*` **and** a `MAC_*` variant and use them in the matching
     Raise layer.
   - **Keep both Raise layers in sync:** same arrangement, only the `WIN_*` / `MAC_*` defines differ.
   - Update the ASCII comment above the layer.
3. Commit and push. GitHub Actions builds both halves
   (`gh run list --branch dev`, or the repo's *Actions* tab).
4. Download the `firmware` artifact from the run.
5. Flash each half: `LWR` + `RSE` → `BOOT` on that half (or double-tap reset), then copy the
   matching `.uf2` (`corne_left…` / `corne_right…`) onto the `NICENANO` drive.
6. Test on Windows **and** macOS, then merge into `master`.

### Common bindings

| Binding | Effect | ZMK docs |
|---|---|---|
| `&kp X`, `&kp RA(X)`, `&kp LS(X)` | Key press, with modifier | [Key press](https://zmk.dev/docs/keymaps/behaviors/key-press), [Modifiers](https://zmk.dev/docs/keymaps/modifiers) |
| `&mo L`, `&tog L`, `&to L`, `&trans` | Layer hold / toggle / switch / fall through | [Layers](https://zmk.dev/docs/keymaps/behaviors/layers) |
| `zmk,behavior-macro` | Key sequences (dead keys, Raise Ctrl/Shift) | [Macros](https://zmk.dev/docs/keymaps/behaviors/macros) |
| `zmk,conditional-layers` | `LWR` + `RSE` → Adjust | [Conditional layers](https://zmk.dev/docs/keymaps/conditional-layers) |
| `&bt BT_SEL n`, `&bt BT_CLR` | Bluetooth profiles | [Bluetooth](https://zmk.dev/docs/keymaps/behaviors/bluetooth) |
| `&bootloader` | Enter bootloader | [Reset](https://zmk.dev/docs/keymaps/behaviors/reset) |
| `&mt MOD KEY` | Hold = modifier, tap = key | [Hold-tap](https://zmk.dev/docs/keymaps/behaviors/hold-tap) |

All key code names: [List of keycodes](https://zmk.dev/docs/keymaps/list-of-keycodes).
Keymap basics: [Keymaps](https://zmk.dev/docs/keymaps). Repo/CI setup: [User setup](https://zmk.dev/docs/user-setup).

### Build settings

- **ZMK version** – `config/west.yml` pins ZMK to a known-good `main` commit. Switch to `v0.4`
  once it is released (first release with Zephyr 4.1).
- **Board** – `build.yaml` uses `nice_nano//zmk` (Zephyr 4.1 naming, formerly `nice_nano_v2`, see
  [ZMK blog](https://zmk.dev/blog/2025/12/09/zephyr-4-1)).
- **Kconfig** – `config/corne.conf`: `CONFIG_BT_CTLR_TX_PWR_PLUS_8` (range), debounce timings;
  sleep and USB logging are available but commented out.

## 4. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Wrong symbol (e.g. `"` instead of `@`) | Binding uses a US key name | Use a `CH_*` / `WIN_*` / `MAC_*` define |
| Symbols wrong only on one OS | Wrong mode active | `LWR` + `RSE` → `MAC` to toggle; check nice!view shows `Mac` |
| macOS: symbols work in VS Code but not in a terminal (WezTerm) | Terminals treat **left** Option as Meta | Keep `MAC_*` on `RA(...)` (right Option) |
| macOS: `<` `>` print `§` `°` | macOS swaps ISO keys `NUBS` and `GRAVE` on ZMK boards | Mac layer sends `GRAVE` for `<` `>`; if it flips after changing the macOS keyboard type, swap back to `NUBS` |
| CI: `Invalid BOARD` | Old board name after a ZMK update | Use `nice_nano//zmk` in `build.yaml` |
| Build breaks without local change | Upstream ZMK changed | Keep `config/west.yml` pinned; read the error in `gh run view <id> --log-failed` |
