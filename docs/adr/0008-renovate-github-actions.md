# 0008. Renovate keeps the GitHub Actions up to date

- Status: Accepted
- Date: 2026-11-12

## Context

The `uses:` pins in the workflows drift silently (artcraft-nixos hit the Node 20
runtime deprecation that way). nvfetcher only tracks ElegooSlicer, not the CI
tooling.

## Decision

Run **Renovate** (self-hosted via `.github/workflows/renovate.yml`) scoped to the
`github-actions` manager only. It runs weekly, opens grouped `ci(deps): …` PRs (the
`ci` type does not trigger a release), and **auto-merges minor/patch/digest** bumps
once CI is green; **major** bumps open a PR for review. Config lives in
`renovate.json`.

Runners are pinned to `ubuntu-24.04` (not `ubuntu-latest`); Renovate must not bump
that label, so a runner change stays an explicit, reviewed change.

Division of labour:

- **nvfetcher** → ElegooSlicer version (`_sources/`, `nvfetcher.toml`).
- **Renovate** → GitHub Actions `uses:` pins.
- **release-please** → our own SemVer releases.

## Consequences

- Action drift is caught automatically.
- Renovate edits files under `.github/workflows/`, which GitHub only allows with a
  token carrying **Workflows: Read and write**; `ELEGOO_BOT_TOKEN` includes it.
- `renovate.json` also works with the hosted Renovate GitHub App, a drop-in
  alternative that needs no token.

## Alternatives considered

- **Hosted Renovate App only**: no token to manage, but configured outside the repo.
- **Renovate for `flake.lock`**: the self-hosted action has no Nix runtime; nixpkgs
  refreshes stay manual for now.
