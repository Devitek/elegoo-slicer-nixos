# 0003. Use nvfetcher to track upstream releases

- Status: Accepted
- Date: 2026-11-12

## Context

The repository must always offer the latest ElegooSlicer release with a correct Nix
hash, with minimal human intervention. Upstream tags use four segments
(`v1.5.3.5`) and attach the Linux AppImage to each GitHub release.

## Decision

Track upstream with **nvfetcher**. `nvfetcher.toml` has a single `elegoo-slicer`
entry using `src.github` (latest release) with `src.prefix = "v"` and a templated
`fetch.url`:

```toml
fetch.url = "https://github.com/elegooofficial/ElegooSlicer/releases/download/v$ver/ElegooSlicer_Linux_V$ver.AppImage"
```

nvfetcher writes `_sources/generated.{json,nix}` (version + SRI hash). The update
workflow (`update.yml`) runs `scripts/update.sh`, verifies the result with
`nix flake check`, and lands a PR (ADR-0005).

## Consequences

- No hand-edited hashes; `_sources/` is machine-managed and excluded from linting.
- **Asset name drift.** Upstream has already shipped the AppImage under another name
  (`ElegooSlicer_Linux_Ubuntu2404_V…`). nvfetcher can only substitute `$ver`, so if
  the name changes again the fetch fails: the update run goes red and nothing is
  merged. The fix is a one-line change to the template in `nvfetcher.toml`.
- Upstream pre-releases are ignored (`src.github` follows the latest stable release).

## Alternatives considered

- **Custom script resolving the asset through the GitHub API**: robust to renames,
  but diverges from the nvfetcher setup shared with artcraft-nixos. A red update run
  is a visible, cheap failure, so the simple template wins for now.
- **Renovate for the AppImage**: no first-class support for Nix hashes of release
  assets. Rejected.
