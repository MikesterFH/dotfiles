# 0017: Windows CLI tools without a winget package come from mise

**Context:** On Windows the CLI tool Applications come from the winget manifest (ADR 0006, 0008); mise only supplies Neovim and the tree-sitter CLI there, pinned (ADR 0013). hunk, the terminal diff viewer, has no winget package, but its GitHub releases ship a windows/amd64 build that mise's aqua backend installs.

**Decision:** a CLI tool with no winget package but an aqua-installable Windows release is listed in `$windowsViaMise` in `dot_config/mise/config.toml.tmpl` and installed by mise on Windows, at latest. hunk is the first. macOS keeps it in the Brewfile and Linux in the mise config like every other CLI tool. The Windows assert allows these aqua entries next to the pinned ones and checks each is present.

**Consequences:** such a tool updates with `mise upgrade`, not `winget upgrade`. If it later gets a winget package, it moves into the winget manifest and out of `$windowsViaMise`. On Windows on ARM, hunk is left out of the mise config, since its release has no windows/arm64 build and one tool mise can't install fails the whole `mise install`.
