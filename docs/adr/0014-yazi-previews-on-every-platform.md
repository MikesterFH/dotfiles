# 0014: Yazi previews on every platform

**Context:** `yazi.toml` routes archives, images, SVGs, PDFs, fonts, JSON and videos to previewers that shell out to 7-Zip, ImageMagick 7 (`magick`), resvg, poppler (`pdftoppm`), jq and ffmpeg, and yazi detects file types with `file`. None of them was installed by the repo, so those previews stayed empty wherever they hadn't been installed by hand. The shell aliases had a sibling problem: `ls` and `cat` were aliased to eza and bat unconditionally, so a missing eza broke `ls`.

**Decision:** `7zip`, `imagemagick`, `poppler`, `resvg`, `jq`, `ffmpeg`, `file` and `eza` join the CLI tool Applications of every Profile (and `zsh`, see ADR 0015), each mapped once per platform:
- macOS: Homebrew formulae (`sevenzip`, which provides `7zz`, plus the others under their own names); `file` ships with macOS.
- Linux: apt for `7zip`, `poppler-utils`, `jq`, `ffmpeg`, `file`; mise for the rest. eza and resvg come as aqua tools. ImageMagick comes from `conda:imagemagick`, the only conda tool, because apt ships ImageMagick 6 and aqua has no build. resvg publishes Linux binaries for amd64 only, so the mise config leaves it out on other architectures: a single tool mise can't install would fail the whole `mise install`.
- Windows: winget (`7zip.7zip`, `ImageMagick.ImageMagick`, `oschwartz10612.Poppler`, `linebender.resvg`, `jqlang.jq`, `Gyan.FFmpeg`, `eza-community.eza`); `file` is Git for Windows' `file.exe`, which `run_after_set-yazi-env-windows` already points yazi at. That script now also puts 7-Zip on the user PATH, which its installer never does, and ImageMagick when its installer skipped that step.

The `ls`/`cat` aliases are set only when eza/bat exist.

**Consequences:** archive, image, SVG, PDF, font, JSON and video previews work on macOS, Debian/Ubuntu and Windows. ffmpeg and ImageMagick are heavy (several hundred MB together), and they install on dev-server too, since CLI tools are the same on every Profile. On Linux arm64 SVGs get no preview. The conda backend is newer in mise than aqua; if it breaks, the ImageMagick preview is the only thing affected.
