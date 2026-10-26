# 0019: mermaid-cli comes from mise's npm backend on every OS

**Context:** snacks.nvim's image viewer renders Mermaid code blocks in Markdown by calling `mmdc` (mermaid-cli). Without it the diagrams stay plain code. mermaid-cli is an npm package: there is no winget or apt package, and no prebuilt release binary for aqua. A local Neovim config also carried image.nvim + diagram.nvim for this, which would duplicate snacks' image rendering on macOS/Linux and needs the same `mmdc`.

**Decision:** mermaid-cli is a CLI tool Application, installed by mise's npm backend (`npm:@mermaid-js/mermaid-cli`) on every OS, at latest. It is listed in `$everywhereViaMise` in `dot_config/mise/config.toml.tmpl`, on top of the `node` runtime mise already installs (ADR 0011), so no manifest (Brewfile, apt, winget) carries it. Both assert scripts check the entry. image.nvim and diagram.nvim are not adopted; snacks.nvim is the only image viewer in Neovim.

**Consequences:** mermaid-cli updates with `mise upgrade`. Its install pulls a headless Chromium through puppeteer, so the first `mise install` is larger and needs access to Google's Chrome download host; behind a restrictive proxy, `PUPPETEER_SKIP_DOWNLOAD` plus a system browser is the fallback. Inline rendering still depends on the terminal (kitty graphics protocol: kitty, Ghostty, WezTerm; WezTerm only as floats).
