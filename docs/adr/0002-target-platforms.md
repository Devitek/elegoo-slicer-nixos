# 0002. Target `x86_64-linux` only

- Status: Accepted
- Date: 2026-11-12

## Context

Upstream releases contain a single Linux artifact: an x86_64 AppImage. There is no
aarch64 build. Since we repackage that artifact (ADR-0001), there is nothing to
package for other architectures.

## Decision

The flake only declares `x86_64-linux`. `meta.platforms = [ "x86_64-linux" ]`, and CI
runs `nix flake check` on an `ubuntu-24.04` (x86_64) runner only.

## Consequences

- One CI job, one required status check besides lint.
- `aarch64-linux` users get no package; they can use `orca-slicer` from nixpkgs or
  build ElegooSlicer from source themselves.
- If upstream ever publishes an aarch64 AppImage, adding it is a new `nvfetcher.toml`
  entry plus the system in `flake.nix` and a second CI job.

## Alternatives considered

- **Build from source for aarch64 only**: two packaging models to maintain for a
  niche target. Rejected.
