# WezTerm: workspaces, mux persistence, and what survives closing the app

Research note. Scope: what WezTerm's "workspace" concept actually is, what
state survives (a) closing GUI windows, (b) the mux server process ending,
and (c) a full application/Windows restart, and which official mechanism
best gets open tabs back after closing WezTerm on **Windows**, given an
installed version as old as `20240203-110809-5046fc22`.

All claims below are sourced from WezTerm's own docs site (wezterm.org,
generated from `github.com/wezterm/wezterm:docs/*.md`) and the project's
GitHub issue tracker. No runtime config in this repo was changed to produce
this note.

## 1. The core concepts, precisely

- **Local domain**: the default set of tabs/windows the GUI manages itself.
  Local-domain tabs "persist until they are closed" — i.e. only for the
  lifetime of the GUI process; there is no server behind them.
  [Multiplexing — overview](https://wezterm.org/multiplexing.html)
- **Multiplexing domain (mux domain)**: "a distinct set of windows and tabs."
  Unix/SSH/TLS domains are backed by a separate **multiplexer server**
  process that keeps running independently of any GUI client attached to
  it. "There may be multiple GUI processes running **in addition to** a
  multiplexer server" — i.e. the GUI and the mux server are distinct OS
  processes. [`wezterm cli`](https://wezterm.org/cli/cli/index.html),
  [Multiplexing — overview](https://wezterm.org/multiplexing.html)
- **Workspace**: "Every MuxWindow is associated with a workspace, which is
  just a label... wezterm doesn't have an exact match to tmux sessions, but
  does have a similar concept known as Workspaces." The GUI only renders
  windows belonging to the *active* workspace; switching workspace "swaps
  the contents of the GUI windows with the MuxWindows that belong to the
  now-focused workspace."
  [Workspaces / Sessions](https://raw.githubusercontent.com/wezterm/wezterm/main/docs/recipes/workspaces.md)

**Important distinction a workspace is *not*:** a workspace is an in-memory
grouping label tracked by whichever process (GUI or mux server) currently
holds the windows. It is *not* a saved/serialized session file. Nothing in
the docs describes workspaces being written to disk; they exist only as
long as the process holding them is alive. `wezterm.mux.get_workspace_names()`
and `get_active_workspace()` simply query the live, in-memory state of
whatever mux the Lua code is running against.
[`wezterm.mux.get_workspace_names()`](https://wezterm.org/config/lua/wezterm.mux/get_workspace_names.html),
[`wezterm.mux.get_active_workspace()`](https://wezterm.org/config/lua/wezterm.mux/get_active_workspace.html)

## 2. What persists across which kind of "closing"

| Event | Local domain only (no mux) | Unix-domain mux server in use |
|---|---|---|
| **Close one GUI window, others remain** | Other windows/tabs fine; closed one's panes/processes are gone | Same — unaffected panes on the server are untouched |
| **Close the last GUI window** ("just closing WezTerm") | Whole app quits — `quit_when_all_windows_are_closed = true` is the default, so this is a full app exit — **all tabs and their processes die** | GUI client process exits, but the **separate `wezterm-mux-server` process keeps running** with all its panes/shells alive, because it was started as an independently daemonized process, not as a child that dies with the GUI |
| **Re-launch WezTerm afterward** | Starts fresh — nothing restored | Re-launching reconnects (via `default_gui_startup_args = {'connect', <domain>}`) to the still-running server and **the exact tabs/panes/workspaces reappear**, including shell history/buffer state, because the processes never actually stopped |
| **Kill/crash the mux server, log off, or reboot Windows** | N/A (nothing to kill) | The server process and every child shell/process under it terminate. **Nothing is preserved** — there is no on-disk session snapshot |

Citations: `quit_when_all_windows_are_closed` defaults to `true` and
terminates the app when all windows close
([`quit_when_all_windows_are_closed`](https://wezterm.org/config/lua/config/quit_when_all_windows_are_closed.html)).
The "spawn a server if needed and then connect the gui to it automatically"
language, and the WSL example that explicitly daemonizes the server
(`serve_command = { 'wsl', 'wezterm-mux-server', '--daemonize' }`), confirm
the mux server is a separate, detachable process from the GUI
([Multiplexing — Unix Domains](https://raw.githubusercontent.com/wezterm/wezterm/main/docs/multiplexing.md)).

So the sharp distinction the user asked about is:

- **"Just closing WezTerm windows"** (GUI quits, Windows session stays up,
  mux server process untouched) → **fully recoverable** today, by design,
  if a unix-domain mux server is in use.
- **"Application shutdown"** in the sense of the mux server process itself
  ending (explicit kill, log-off, reboot) → **not recoverable**; WezTerm has
  no official facility that serializes pane/tab/workspace state to disk and
  replays it. Only a *static, hand-written* layout can be replayed (section
  4), and it will recreate fresh shells, not resume the previous ones.

## 3. Historical bug relevant to "old version" concern — already fixed

An older bug (`wez/wezterm#2614`, filed against `20221009-202607-cb31c35b`,
Windows) meant that **if every tab in a unix-domain mux window was closed**,
the GUI could not re-spawn a new tab into that domain without restarting
the whole GUI process (`"window_id 1 not found on this server"`). It was
fixed and closed on 2022-10-12, labelled `fixed-in-nightly`, well before the
`20240203` build in question, so this shouldn't affect the installed
version.
[`wez/wezterm#2614`](https://github.com/wezterm/wezterm/issues/2614)

Feature availability relevant to this note, all predating `20240203`:

- `default_workspace`, `SwitchToWorkspace`, `SwitchWorkspaceRelative` — since `20220319-142410-0fcdea07`
- `gui-startup`, `mux-startup`, `wezterm.mux.get_active_workspace()` /
  `get_workspace_names()` — since `20220624-141144-bd1b7c5d`
- `wezterm cli rename-workspace` — since `20230408-112425-69ae8472`
- `quit_when_all_windows_are_closed` — since `20230320-124340-559cb7b0`
- `default_mux_server_domain` (standalone mux server default domain) — since `20230712-072601-f4abf8fd`

All of the above is therefore present and usable on `20240203-110809-5046fc22`.
(Sources: the respective per-feature doc pages linked throughout this note,
each carrying an explicit `Since: Version ...` marker.)

## 4. Available approaches, compared

### 4a. Mux server/domain with attach/reconnect (the actual persistence mechanism)

Configure a `unix_domains` entry and point `default_gui_startup_args` at it
so the GUI always reconnects on launch:

```lua
config.unix_domains = { { name = 'unix' } }
config.default_gui_startup_args = { 'connect', 'unix' }
```

"This causes `wezterm` to act as though it was started as `wezterm connect
unix` by default... If you prefer to connect manually, leave out this line."
[Multiplexing — Unix Domains](https://raw.githubusercontent.com/wezterm/wezterm/main/docs/multiplexing.md)

This is the **only** mechanism here that gives you literal persistence of
running processes (shells, editors, builds) across closing the GUI
windows. It does not, by itself, survive the mux server process itself
dying (crash, explicit kill, logoff, reboot). Unix domains are documented
to work "on all systems, even Windows" via `AF_UNIX`, citing Microsoft's
own announcement of `AF_UNIX` support on Windows.
[Multiplexing — Unix Domains](https://raw.githubusercontent.com/wezterm/wezterm/main/docs/multiplexing.md)

Related, narrower tools for working with an existing mux domain:
`wezterm cli list` (enumerate windows/tabs/panes/workspace per pane, with
`--format json`) and `AttachDomain(domain_name)` (re-attach a GUI to a
named domain's existing panes, spawning a default program only if the
domain currently has no panes).
[`wezterm cli list`](https://wezterm.org/cli/cli/list.html),
[`AttachDomain`](https://wezterm.org/config/lua/keyassignment/AttachDomain.html)

### 4b. Workspaces (rename / switch / activation)

Workspaces organize *already-running* mux windows into named groups so you
can flip between unrelated projects without opening new GUI windows for
each; they do not add any persistence of their own beyond whatever domain
(local or mux) the windows actually live in.

- `SwitchToWorkspace{ name = ..., spawn = ... }` — switches to (creating if
  necessary) a workspace, optionally spawning a given command into it if
  new. [`SwitchToWorkspace`](https://wezterm.org/config/lua/keyassignment/SwitchToWorkspace.html)
- `SwitchWorkspaceRelative(n)` — cycle through workspaces in lexicographic
  name order. [`SwitchWorkspaceRelative`](https://wezterm.org/config/lua/keyassignment/SwitchWorkspaceRelative.html)
- `wezterm cli rename-workspace NEW-NAME` — rename the workspace containing
  the current pane (`--workspace`/`--pane-id` to target explicitly), since
  `20230408-112425-69ae8472`.
  [`wezterm cli rename-workspace`](https://wezterm.org/cli/cli/rename-workspace.html)
- `ShowLauncherArgs{ flags = 'FUZZY|WORKSPACES' }` — launcher-based picker
  over existing workspaces. [`SwitchToWorkspace`](https://wezterm.org/config/lua/keyassignment/SwitchToWorkspace.html)

If workspaces are only ever created on the **local** domain, closing the
last window still triggers full-app quit and loses them — workspaces add
no persistence on their own; the domain underneath them does.

### 4c. Config-based startup/session layout (`gui-startup` / `mux-startup`)

These Lua events let you declare a fixed layout of windows/panes/workspaces
that gets (re-)created every time the GUI or the mux server starts "cold"
(i.e. only when no panes already exist for the default program to attach
to):

- `gui-startup` fires once when `wezterm start` launches the GUI server,
  before any default program, and **does not fire** for `wezterm connect`.
  If it spawns panes, those take precedence over the default program.
  [`gui-startup`](https://raw.githubusercontent.com/wezterm/wezterm/main/docs/config/lua/gui-events/gui-startup.md)
- `mux-startup` is the equivalent event for the standalone mux server,
  firing once when the mux server process itself starts up (so it only
  runs once per server lifetime, not once per GUI reconnect).
  [`mux-startup`](https://wezterm.org/config/lua/mux-events/mux-startup.html)

This is **not** a save/restore of actual running state — it is a
declarative, hand-authored recipe that recreates a *fresh* set of panes
(new shells, re-run commands) whenever the server or GUI boots cold. It is
the closest official mechanism to "get my usual layout back after a full
restart," but it reconstructs the shape, not the history/content, of a
session.

### 4d. Official session-save/restore facilities — there are none

Searching the current docs tree and the WezTerm GitHub repo turns up no
official, built-in feature that serializes the current set of
windows/tabs/panes/workspaces to disk and restores them automatically on
next launch (equivalent to tmux-resurrect or VS Code's window restore).
The closest adjacent primitives are:

- `mux-is-process-stateful` — a hook used only to decide whether to prompt
  before *killing* a pane (stateful vs. disposable process trees); it has
  nothing to do with saving/restoring state.
  [`mux-is-process-stateful`](https://wezterm.org/config/lua/mux-events/mux-is-process-stateful.html)
- `wezterm cli list --format json` — lets you *read* the live layout
  (window/tab/pane ids, workspace, size, cwd) at a point in time, which is
  the kind of data a snapshot tool would need, but WezTerm does not ship
  any built-in snapshot/replay tool around it.
  [`wezterm cli list`](https://wezterm.org/cli/cli/list.html)

Third-party community plugins (e.g. `wezterm-session-manager`,
`resurrect.wezterm`) build save/restore on top of exactly this `wezterm
cli` surface, but they are **not part of WezTerm itself** and are outside
the scope of "official primary sources" for this note — flagged here only
so the gap isn't mistaken for an oversight.

## 5. Windows-specific limitations to keep in mind

1. **Unix-domain sockets do work on Windows.** The docs explicitly say unix
   domains are "supported on all systems, even Windows," citing Microsoft's
   `AF_UNIX` support, and are how the native Win32 GUI can even reach into
   WSL. [Multiplexing — Unix Domains](https://raw.githubusercontent.com/wezterm/wezterm/main/docs/multiplexing.md)
2. **WSL interop over a unix-domain socket only works with WSL 1.** "WSL 2
   doesn't support AF_UNIX interop" (linking `microsoft/WSL#5961`), so the
   socket-sharing recipe for connecting the Windows GUI into a WSL-hosted
   mux server does not apply to WSL 2 distros.
   [Multiplexing — Connecting into WSL](https://raw.githubusercontent.com/wezterm/wezterm/main/docs/multiplexing.md)
   This repo's config instead uses the separate `wsl_domains` /
   `WslDomain` mechanism (spawning directly into a named WSL distribution)
   rather than a shared unix socket — a different, non-persistent-by-default
   path (`dot_config/wezterm/config/general.lua:19-26`, repo file, not an
   upstream source).
3. **No documented Windows-native autostart/service equivalent.** On Linux,
   admins commonly wire a systemd user unit to keep the mux server alive
   across logins; the current WezTerm docs contain no analogous
   Windows-service example. In practice the server is only (re)spawned the
   next time a WezTerm GUI process runs `connect`/`start --domain` against
   it — there's no persistence across a full logoff/reboot without manual
   intervention. [Multiplexing — overview](https://raw.githubusercontent.com/wezterm/wezterm/main/docs/multiplexing.md) (absence confirmed by reading the full page; no systemd/Windows-service section exists in the current doc source)
4. **`quit_when_all_windows_are_closed` defaults to `true`.** Combined with
   point 3, if the only running piece is the GUI (local domain, no mux),
   there is nothing left to reconnect to once the last window closes.
   [`quit_when_all_windows_are_closed`](https://wezterm.org/config/lua/config/quit_when_all_windows_are_closed.html)
5. **A previously real Windows-specific mux bug is already fixed** on the
   installed `20240203` build — see §3.

## 6. What this repo's current WezTerm config already does

`dot_config/wezterm/config/general.lua` (this repo) already configures:

```lua
Config.unix_domains = { { name = "persistent" } }
Config.default_gui_startup_args = { "connect", "persistent" }
```

Per §2/§4a, this means the installed setup **already** spawns/attaches a
background `wezterm-mux-server` and reconnects to it automatically on every
GUI launch. In the common case of simply closing WezTerm's window(s)
without logging off or rebooting, tabs should already be surviving and
reappearing on next launch, because the server process backing the
`persistent` domain is never torn down by closing the GUI alone. What is
**not** currently configured is any `gui-startup`/`mux-startup` hook to
rebuild a specific named-workspace layout on a cold server start (§4c),
and — by design of the project, not a gap in this config — there is no
official way to survive the `persistent` server process itself being
killed, log-off, or a reboot (§4d).

## 7. Practical recommendations

### Configured workspace shortcuts

Press `Ctrl+F`, release it, then press the second key:

| Second key | Action |
| --- | --- |
| `Shift+W` | Fuzzy picker for existing workspaces |
| `Shift+N` | Prompt for a workspace name; create it or switch to the existing one |
| `[` | Previous workspace (lexicographic name order) |
| `]` | Next workspace (lexicographic name order) |
| `Shift+X` | Delete the current workspace after confirmation; terminate all its tabs, panes and processes |

The deletion dialog defaults to Cancel; Escape also cancels. Deletion
affects all windows in the selected workspace, not other workspaces.
Closing the final pane removes the workspace. This is destructive and is
not a detach operation; deleting the last workspace may close the GUI.

A new workspace starts in the current pane's domain and, when known, its
working directory. Selecting an existing workspace does not spawn another
shell or reset its layout. The status bar already displays the active
workspace name. These shortcuts do not save a session to disk.

Layouts are useful as optional, repeatable project templates. For example,
a `dev` workspace could contain an `edit` tab with an editor on the left
(70%) and a shell on the right (30%), plus a `tests` tab. A separate `ops`
workspace could contain independent shell and log tabs. Create such a
layout only when its workspace is new, not on every switch or reconnect:
otherwise reconnecting duplicates tabs or disrupts a live session.
No automatic layout is configured.

Given the distinction the user drew — "closing GUI windows" vs. "app
shutdown" — and that an official session-snapshot facility does not exist:

- **For "I just closed the window(s), I want my tabs back"**: nothing to
  change. The existing `unix_domains`/`default_gui_startup_args =
  {'connect','persistent'}` setup already provides this, per §2/§6. Confirm
  it's working by checking `wezterm cli list` after closing all windows —
  if the mux server is still alive, panes should still be listed.
  [`wezterm cli list`](https://wezterm.org/cli/cli/list.html)
- **For "I want a consistent set of tabs/workspaces to reappear after a
  genuine restart (logoff/reboot/killed server)"**: add a `mux-startup`
  (preferred, since it only runs once per *server* lifetime rather than
  per GUI reconnect) hook that calls `mux.spawn_window{ workspace = ... }`
  per project/workspace, as shown in the official recipe. This recreates
  the *shape* of a session (workspaces, panes, starting commands/`cwd`),
  not the exact history of what was running — there is no official way to
  get the latter back after the server process itself is gone. §4c, §4d
- **Do not rely on workspaces alone** for persistence — they're an
  organizational label on top of whatever domain the windows live in; a
  workspace built on the `local` domain disappears the moment the last
  window closes, same as any other local-domain tab. §2, §4b
- **On Windows specifically**, don't expect the `persistent` mux server to
  survive logoff/reboot on its own; there is no documented Windows
  autostart equivalent to a systemd user unit, so the server only comes
  back when WezTerm (or `wezterm-mux-server` directly) is next run. §5

## Sources consulted

- https://wezterm.org/multiplexing.html (and raw source: https://raw.githubusercontent.com/wezterm/wezterm/main/docs/multiplexing.md)
- https://raw.githubusercontent.com/wezterm/wezterm/main/docs/recipes/workspaces.md
- https://raw.githubusercontent.com/wezterm/wezterm/main/docs/config/lua/gui-events/gui-startup.md
- https://wezterm.org/config/lua/mux-events/mux-startup.html
- https://wezterm.org/config/lua/mux-events/mux-is-process-stateful.html
- https://wezterm.org/config/lua/config/default_workspace.html
- https://wezterm.org/config/lua/config/default_mux_server_domain.html
- https://wezterm.org/config/lua/config/quit_when_all_windows_are_closed.html
- https://wezterm.org/config/lua/keyassignment/SwitchToWorkspace.html
- https://wezterm.org/config/lua/keyassignment/SwitchWorkspaceRelative.html
- https://wezterm.org/config/lua/keyassignment/AttachDomain.html
- https://wezterm.org/config/lua/wezterm.mux/get_active_workspace.html
- https://wezterm.org/config/lua/wezterm.mux/get_workspace_names.html
- https://wezterm.org/cli/cli/index.html
- https://wezterm.org/cli/cli/list.html
- https://wezterm.org/cli/cli/rename-workspace.html
- https://wezterm.org/cli/connect.html
- https://wezterm.org/cli/start.html
- https://wezterm.org/config/launch.html
- https://wezterm.org/changelog.html (used to confirm `20240203-110809-5046fc22` exists and its position relative to feature `Since:` markers)
- https://github.com/wezterm/wezterm/issues/2614 (historical Windows mux bug, fixed before `20240203`)
- This repo: `dot_config/wezterm/config/general.lua` (current `unix_domains`/`wsl_domains`/`default_gui_startup_args` configuration, read-only)

## Gaps / uncertainties

- Could not find an official WezTerm doc page describing exactly what
  default `serve_command` a unix domain uses on Windows when none is
  specified (the WSL example shows an explicit one); this note infers
  detached/independent-process behavior from the "spawn a server if
  needed" language and the `--daemonize` flag shown in the WSL example,
  not from a Windows-specific worked example.
- Did not verify empirically on the user's machine whether the `persistent`
  unix-domain server is in fact currently running/attached (no commands
  were run against the live WezTerm instance; this is a documentation
  research task only, per the bounded objective).
- Third-party session-manager plugins are mentioned only to flag the gap
  in official tooling; they were not evaluated against primary sources
  since they are not part of the WezTerm project itself.
