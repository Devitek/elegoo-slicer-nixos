# 0004. Dispatch the update workflow from an external cron

- Status: Accepted
- Date: 2026-11-12

## Context

GitHub Actions `schedule` triggers are best-effort. On artcraft-nixos an hourly
`cron` produced only 3 to 5 runs a day, at random minutes, with gaps of 5 to 9
hours. No cron expression fixes that.

## Decision

`update.yml` is primarily started by an **external cron** that calls the
`workflow_dispatch` API:

```sh
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/Devitek/elegoo-slicer-nixos/actions/workflows/update.yml/dispatches \
  -d '{"ref":"main"}'
```

`HTTP 204` means the run was queued. The token needs **Actions: Read and write** on
this repository. The GitHub `schedule` (`37 * * * *`, off the top of the hour) stays
as a backstop.

## Consequences

- Update latency is bounded by the external cron, not by GitHub's scheduler.
- The external scheduler lives outside this repository; if it stops, the GitHub
  backstop still catches up, only more slowly.

## Alternatives considered

- **GitHub schedule only**: free and in-repo, but unreliable (see Context).
- **A NixOS module shipping a systemd timer in this repo**: more moving parts for
  little gain over an existing external cron. Rejected (artcraft-nixos#42).
