#!/usr/bin/env bash
# Refresh _sources/ from upstream via nvfetcher and print a Markdown summary of the
# version bump (empty when nothing changed) to stdout.
#
# Requirements (provided by `nix develop`): nvfetcher, jq.
# Optional: $GITHUB_TOKEN (recommended, avoids GitHub API rate limits).
#
# Usage: nix develop .#default --command bash scripts/update.sh
set -euo pipefail
cd "$(dirname "$0")/.."

gen="_sources/generated.json"

version() {
  [ -f "$gen" ] || return 0
  jq -r '."elegoo-slicer".version // empty' "$gen"
}

before="$(version)"

keyfile="$(mktemp)"
trap 'rm -f "$keyfile"' EXIT
printf '[keys]\ngithub = "%s"\n' "${GITHUB_TOKEN:-}" >"$keyfile"

# Track the latest release and refresh the hash. Quiet on stdout (progress on stderr).
nvfetcher -c nvfetcher.toml -k "$keyfile" 1>&2

after="$(version)"

if [ "$before" != "$after" ]; then
  printf -- '- elegoo-slicer: %s → %s\n' "${before:-new}" "$after"
  printf '\nRelease notes: https://github.com/elegooofficial/ElegooSlicer/releases/tag/v%s\n' "$after"
fi
