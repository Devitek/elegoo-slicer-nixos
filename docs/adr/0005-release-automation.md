# 0005. Auto-merged update PRs and release-please (SemVer)

- Status: Accepted
- Date: 2026-11-12

## Context

Updates should land automatically yet traceably, and the repository's own versions
must follow SemVer with a generated changelog.

## Decision

- **Update delivery**: `update.yml` refreshes `_sources/`, runs `nix flake check`
  as the authoritative gate, then opens a `chore(deps): update ElegooSlicer to <ver>`
  PR and merges it (squash).
- **Releases**: `release-please` (`release-type: simple`, manifest-driven) turns
  Conventional Commits into SemVer tags, GitHub Releases and `CHANGELOG.md`. Its
  workflow enables **native auto-merge on its own release PR**, so releases do not
  linger open.
- **Tokens**: workflows use `secrets.ELEGOO_BOT_TOKEN` when present, else
  `GITHUB_TOKEN`.

## Consequences

- Fully hands-off happy path: upstream release → verified → merged → released. Each
  release of this repo is a reproducible snapshot of an ElegooSlicer version.
- Every change is a PR with a build log and a Conventional Commit.
- The repo settings must allow squash merges and auto-merge.
- The release-please job has no checkout, so `gh` is pointed at the repository with
  `GH_REPO` (otherwise `gh pr list` silently returns nothing, see artcraft-nixos#48).

## Token

`ELEGOO_BOT_TOKEN` is a fine-grained Personal Access Token scoped to this repository
with **Contents, Pull requests, Issues and Workflows: Read and write**. The Devitek
organisation rejects fine-grained PATs valid for more than **366 days** (every API
call returns `403`), so the token must be renewed yearly. `update.yml` checks the
token against the API first and fails loudly when it is expired or rejected.

Without the PAT, a PR or push made with `GITHUB_TOKEN` does **not** trigger other
workflows: bot PRs get no `ci.yml` run, so the required checks never report and the
PR cannot merge under branch protection. The PAT is therefore required.

## Alternatives considered

- **Direct push to main**: simpler but no PR trail; rejected for traceability.
- **Manual merge of update PRs**: safe but defeats the automation.
