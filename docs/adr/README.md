# Architecture Decision Records

Lightweight records of the structural decisions behind `elegoo-slicer-nixos`.
Format inspired by [MADR](https://adr.github.io/madr/).

| # | Decision | Status |
| --- | --- | --- |
| [0001](0001-prebuilt-appimage.md) | Package the upstream AppImage, not from source | Accepted |
| [0002](0002-target-platforms.md) | Target `x86_64-linux` only | Accepted |
| [0003](0003-update-mechanism.md) | Use nvfetcher to track upstream releases | Accepted |
| [0004](0004-external-trigger.md) | Dispatch the update workflow from an external cron | Accepted |
| [0005](0005-release-automation.md) | Auto-merge update PRs + release-please (SemVer) | Accepted |
| [0006](0006-fhs-runtime.md) | Run the AppImage in an FHS env with the host libs it expects | Accepted |
| [0007](0007-dev-environment.md) | Reproducible dev env via flake devShell | Accepted |
| [0008](0008-renovate-github-actions.md) | Renovate keeps the GitHub Actions up to date | Accepted |
| [0009](0009-unexport-bundled-freetype.md) | Hide the bundled FreeType exported by the binary | Accepted |

## Template

```markdown
# NNNN. Title

- Status: Proposed | Accepted | Superseded by ADR-XXXX
- Date: YYYY-MM-DD

## Context
## Decision
## Consequences
## Alternatives considered
```
