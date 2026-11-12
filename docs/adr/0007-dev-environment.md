# 0007. Reproducible dev environment via flake devShell

- Status: Accepted
- Date: 2026-11-12

## Context

Contributors and CI need the same tools: nvfetcher, the Nix linters, `gh`. This is a
Nix-only repository, so Nix itself is the natural way to pin them.

## Decision

Expose `devShells.<system>.default` in `flake.nix` with `nvfetcher`, `nix-prefetch`,
`jq`, `gh`, `nixfmt`, `statix`, `deadnix` and `shellcheck`, and `formatter` =
`nixfmt` for `nix fmt`. CI runs every lint and the updater through
`nix develop .#default --command …`.

## Consequences

- Same tool versions locally and in CI, pinned by `flake.lock`.
- No extra tooling to install beyond Nix with flakes enabled.

## Alternatives considered

- **devbox / direnv-only setups**: another layer on top of Nix for no gain here.
