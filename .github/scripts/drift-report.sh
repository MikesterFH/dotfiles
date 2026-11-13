#!/usr/bin/env bash
# drift-report.sh [MARKDOWN_FILE]
#
# Compares, for every Application with both a `mise` and a `nix` field in
# home/.chezmoidata/applications.toml, the version mise.lock installs on the
# chezmoi Targets with the one the Nix module installs on the NixOS hosts
# (docs/adr/0023-applications-from-one-data-file.md). Same major and minor:
# fine. Different minor: a warning. Different major: an error, exit 1.
#
# Prints GitHub annotations and a Markdown table, also appended to
# $GITHUB_STEP_SUMMARY in CI and written to MARKDOWN_FILE if given. The Nix
# side comes from the CI consumer's `versions` output, built from this
# checkout's flake.lock, so the report covers exactly the two lockfiles in
# the working tree.
#
# Needs nix (flakes) and python3 (3.11+, tomllib).
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

nix eval --json --override-input dotfiles "path:$repo" "$repo/nix/ci#versions" > "$tmp/nix.json"

python3 - "$repo/home/.chezmoidata/applications.toml" "$repo/home/dot_config/mise/mise.lock" "$tmp/nix.json" "${1:-}" <<'EOF'
import json, os, re, sys, tomllib

apps_path, lock_path, nix_path, markdown_path = sys.argv[1:]
apps = tomllib.load(open(apps_path, "rb"))["application"]
locked = tomllib.load(open(lock_path, "rb")).get("tools", {})
nix = json.load(open(nix_path))

def mise_version(app):
    request = app.get("version", "latest")
    entries = locked.get(app["mise"], [])
    for e in entries:
        if request in e.get("specifiers", []):
            return e["version"]
    return entries[0]["version"] if entries else None

def parts(version):
    # 7.1.2_31 (conda) and 7.1.2-34 (nixpkgs) → [7, 1, 2, 31]
    return [int(n) for n in re.findall(r"\d+", version)]

rows, errors, warnings = [], 0, 0
for app in apps:
    if "mise" not in app or "nix" not in app:
        continue
    name, m, n = app["name"], mise_version(app), nix.get(app["name"])
    if m is None or n is None:
        status = "not comparable"
        print(f"::warning::drift: {name}: no version on the {'mise' if m is None else 'Nix'} side")
        warnings += 1
    else:
        a, b = parts(m), parts(n)
        if a[:1] != b[:1]:
            status = "major"
            print(f"::error::drift: {name}: mise {m}, Nix {n} (major)")
            errors += 1
        elif a[:2] != b[:2]:
            status = "minor"
            print(f"::warning::drift: {name}: mise {m}, Nix {n} (minor)")
            warnings += 1
        elif a != b:
            status = "patch"
        else:
            status = "same"
    rows.append(f"| {name} | {m or '–'} | {n or '–'} | {status} |")

table = "\n".join([
    "### Version drift: mise.lock vs Nix module",
    "",
    "| Application | mise.lock | Nix | Drift |",
    "| --- | --- | --- | --- |",
    *rows,
    "",
    f"{len(rows)} Applications, {errors} major, {warnings} minor or not comparable.",
    "",
])
print(table)
for path in (os.environ.get("GITHUB_STEP_SUMMARY"), markdown_path):
    if path:
        with open(path, "a") as f:
            f.write(table)
sys.exit(1 if errors else 0)
EOF
