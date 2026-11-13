#!/usr/bin/env bash
# mise-lock.sh [--check | --bump]
#
# Keeps home/dot_config/mise/mise.lock in step with the Application data file
# (home/.chezmoidata/applications.toml, docs/adr/0023-applications-from-one-data-file.md).
# One lockfile serves every Target, so it covers every Application with a
# `mise` field, on every platform where mise installs it (the same
# `mise_os`/`mise_arch` rule as .chezmoitemplates/applications.json).
#
# Without arguments: starts from the committed lockfile and runs
# `mise lock --global` once per platform, for the tools mise installs there.
# Versions already locked stay as they are; new tools and platforms are
# added, tools gone from the data file are dropped.
#
# --bump: the same, but every `latest`/`lts`/prefix request is re-resolved
# to the newest release (`mise lock --bump`); exact pins stay. The scheduled
# bump PR (.github/workflows/bump.yml) runs this.
#
# --check: no mise needed. Fails when the lockfile is missing a tool or one
# of its platforms, lists a tool no longer in the data file, or was locked
# for a different version request than the data file's (`version`, default
# "latest"). `mise install --locked` fails hard on any of these.
#
# Needs chezmoi, jq and python3 (3.11+, tomllib); generating also needs mise.
# Set GITHUB_TOKEN to avoid GitHub's anonymous API rate limit.
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
lock="$repo/home/dot_config/mise/mise.lock"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# expected.json: {"tools": {tool: version request}, "platforms": {platform: [tool]}}
: > "$tmp/empty.toml"
chezmoi --source "$repo" --config "$tmp/empty.toml" --config-format toml data --format json | jq '
    [.application[] | select(.mise)] as $apps
    | {
        tools: ($apps | map({key: .mise, value: (.version // "latest")}) | from_entries),
        platforms: (
            [["linux", "amd64", "linux-x64"], ["linux", "arm64", "linux-arm64"],
             ["darwin", "amd64", "macos-x64"], ["darwin", "arm64", "macos-arm64"],
             ["windows", "amd64", "windows-x64"], ["windows", "arm64", "windows-arm64"]]
            | map(. as [$os, $arch, $platform]
                | {key: $platform, value: [$apps[]
                    | select((.mise_os == null) or (.mise_os | index($os)))
                    | select((.mise_arch == null) or (.mise_arch[$os] == null) or (.mise_arch[$os] | index($arch)))
                    | .mise]})
            | from_entries)
      }' > "$tmp/expected.json"

check() {
    python3 - "$lock" "$tmp/expected.json" <<'EOF'
import json, sys, tomllib
lock_path, expected_path = sys.argv[1], sys.argv[2]
expected = json.load(open(expected_path))
try:
    locked = tomllib.load(open(lock_path, "rb")).get("tools", {})
except FileNotFoundError:
    print(f"::error::{lock_path} missing; run .github/scripts/mise-lock.sh")
    sys.exit(1)
errors = []
for tool, version in expected["tools"].items():
    entries = locked.get(tool)
    if not entries:
        errors.append(f"{tool} missing")
    elif not any(version in e.get("specifiers", []) for e in entries):
        found = sorted({s for e in entries for s in e.get("specifiers", [])})
        errors.append(f"{tool} locked for {found}, data file asks for {version!r}")
for platform, tools in expected["platforms"].items():
    for tool in tools:
        entries = locked.get(tool, [])
        if entries and not any(f"platforms.{platform}" in e for e in entries):
            errors.append(f"{tool} has no {platform} entry")
for tool in locked:
    if tool not in expected["tools"]:
        errors.append(f"{tool} is not in applications.toml")
for e in errors:
    print(f"::error::mise.lock: {e}")
if errors:
    print("Regenerate with .github/scripts/mise-lock.sh (or the 'mise lock' workflow).")
    sys.exit(1)
print(f"mise.lock matches applications.toml ({len(expected['tools'])} tools)")
EOF
}

bump=()
case "${1:-}" in
    --check) check; exit ;;
    --bump)  bump=(--bump) ;;
    "")      ;;
    *)       echo "usage: $0 [--check | --bump]" >&2; exit 2 ;;
esac

home="$tmp/home"
mkdir -p "$home/.config/mise"
{
    echo "[tools]"
    jq -r '.tools | to_entries[] | "\(.key | tojson) = \(.value | tojson)"' "$tmp/expected.json"
} > "$home/.config/mise/config.toml"
[ -f "$lock" ] && cp "$lock" "$home/.config/mise/mise.lock"

# Drop tools gone from the data file: `mise lock TOOL…` leaves other tools'
# entries alone, stale ones included. Sections are `[[tools."<tool>"]]` and
# `[tools."<tool>".…]`; everything up to the next header belongs to them.
if [ -f "$home/.config/mise/mise.lock" ]; then
    python3 - "$home/.config/mise/mise.lock" "$tmp/expected.json" <<'EOF'
import json, re, sys
path, expected_path = sys.argv[1], sys.argv[2]
keep = set(json.load(open(expected_path))["tools"])
header = re.compile(r'^\[\[?tools\.(?:"((?:[^"\\]|\\.)*)"|([A-Za-z0-9_-]+))')
out, drop = [], False
for line in open(path):
    if line.startswith("["):
        m = header.match(line)
        drop = bool(m) and (m.group(1) or m.group(2)) not in keep
    if not drop:
        out.append(line)
open(path, "w").write("".join(out))
EOF
fi

# A throwaway HOME so no user or project config leaks into the lock.
for platform in $(jq -r '.platforms | keys[]' "$tmp/expected.json"); do
    mapfile -t tools < <(jq -r --arg p "$platform" '.platforms[$p][]' "$tmp/expected.json")
    echo "::group::mise lock $platform (${#tools[@]} tools)"
    (cd "$tmp" && env -u XDG_CONFIG_HOME -u MISE_CONFIG_DIR -u MISE_GLOBAL_CONFIG_FILE \
        HOME="$home" mise lock --global "${bump[@]}" --platform "$platform" "${tools[@]}")
    echo "::endgroup::"
done

# Write through the existing file: mise creates the lockfile with mode 0600.
cat "$home/.config/mise/mise.lock" > "$lock"
check
