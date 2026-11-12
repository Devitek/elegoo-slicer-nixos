# Technical architecture

## Repository layout

```
flake.nix               Flake outputs (packages, apps, overlay, modules, checks, devShell)
nvfetcher.toml          Upstream tracking config (single elegoo-slicer entry)
_sources/generated.*    nvfetcher output: version + url + hash (machine-managed)
pkgs/
  elegoo-slicer.nix     appimageTools.wrapType2 package
  default.nix           Package set, fed by _sources
nix/
  overlay.nix           pkgs.elegoo-slicer
  nixos-module.nix      programs.elegoo-slicer (NixOS)
  hm-module.nix         programs.elegoo-slicer (Home Manager)
scripts/update.sh       nvfetcher wrapper + bump summary
docs/adr/               Architecture Decision Records
.github/workflows/      ci.yml, update.yml, release-please.yml, renovate.yml
```

## Packaging model

Upstream publishes one Linux artifact per release, an x86_64 AppImage
([ADR-0001](adr/0001-prebuilt-appimage.md)). Its layout:

```
AppRun                          sets LC_ALL=C, NVIDIA/Wayland workarounds, then:
libexec/elegoo-slicer-env       checks host libs, sets LD_LIBRARY_PATH, execs:
bin/elegoo-slicer               the slicer (+ bundled Agora RTM SDK libs)
lib/orca-runtime/               bundled zlib, lzma, expat, libmspack
usr/share/{applications,icons/hicolor/192x192,metainfo}
```

`pkgs/elegoo-slicer.nix` wraps it with `appimageTools.wrapType2`, which runs
`AppRun` inside a bwrap FHS environment ([ADR-0006](adr/0006-fhs-runtime.md)):

1. the default appimageTools library set covers GTK3, GStreamer base, libglvnd, GLU,
   libsecret, Wayland/X11, Mesa;
2. `extraPkgs` adds what the AppImage expects from the host on top of that:
   `webkitgtk_4_1`, `libsoup_3`, `glib-networking`, GStreamer good/bad plugins,
   `libmspack`;
3. the FHS profile exports `GDK_PIXBUF_MODULE_FILE` (librsvg's loader cache) so GTK
   can load SVG theme assets;
4. `extraInstallCommands` installs the desktop entry (`Exec=elegoo-slicer`,
   `Icon=elegoo-slicer`) and the icon.

The extracted AppImage and the runtime package list are exposed as
`passthru.extracted` and `passthru.runtimePkgs` for debugging.

The 3D preview uses OpenGL: set `hardware.graphics.enable = true;` on NixOS.

## Sources and versioning

```toml
[elegoo-slicer]
src.github = "elegooofficial/ElegooSlicer"   # latest GitHub release
src.prefix = "v"                              # v1.5.3.5 -> 1.5.3.5
fetch.url = "https://github.com/elegooofficial/ElegooSlicer/releases/download/v$ver/ElegooSlicer_Linux_V$ver.AppImage"
```

`nvfetcher` writes `_sources/generated.nix` (`{ elegoo-slicer = { pname; version; src; }; }`),
read by `pkgs/default.nix`. If upstream renames the asset, the fetch fails and the
template must be adjusted ([ADR-0003](adr/0003-update-mechanism.md)).

## Flake outputs

| Output | Purpose |
| --- | --- |
| `packages.x86_64-linux.elegoo-slicer` / `.default` | The package |
| `apps.x86_64-linux.elegoo-slicer` / `.default` | `nix run` |
| `overlays.default` | `pkgs.elegoo-slicer` |
| `nixosModules.default` | `programs.elegoo-slicer` (system) |
| `homeManagerModules.default` | `programs.elegoo-slicer` (user) |
| `checks.x86_64-linux.elegoo-slicer-smoke` | `elegoo-slicer --help` in the FHS env, no display |
| `checks.x86_64-linux.elegoo-slicer-gui` | Real start-up under Xvfb with a variable font, must survive 30 s ([ADR-0009](adr/0009-unexport-bundled-freetype.md)) |
| `checks.x86_64-linux.nixos-module` / `.home-manager-module` | Module evaluation tests |
| `devShells.x86_64-linux.default`, `formatter.x86_64-linux` | Tooling, `nix fmt` |

## CI/CD

- **ci.yml** (PR + push to `main`): lint (`statix`, `deadnix`, `nixfmt --check` on
  hand-written Nix, `shellcheck`) and `nix flake check` on `ubuntu-24.04`. The runner
  lifts AppArmor's user-namespace restriction first, since bwrap needs it.
- **update.yml** (external cron via `workflow_dispatch`, GitHub schedule as backstop):
  `scripts/update.sh` runs `nvfetcher`; if `_sources/` changed, `nix flake check`
  gates the result, then a `chore(deps): update ElegooSlicer to <ver>` PR is opened
  and merged ([ADR-0004](adr/0004-external-trigger.md),
  [ADR-0005](adr/0005-release-automation.md)).
- **release-please.yml**: SemVer tags, GitHub Releases and `CHANGELOG.md` from
  Conventional Commits; auto-merges its own release PR.
- **renovate.yml**: weekly, keeps the GitHub Actions `uses:` pins current
  ([ADR-0008](adr/0008-renovate-github-actions.md)).

`main` is protected: `lint` and `flake check (x86_64-linux)` are required, branches
must be up to date, history is linear, conversations must be resolved.

### Token note

Workflows prefer `secrets.ELEGOO_BOT_TOKEN` (a fine-grained PAT, renewed yearly) over
`GITHUB_TOKEN`. It is required: PRs opened with `GITHUB_TOKEN` trigger no CI, so the
required checks never report. See ADR-0005.

## How to update manually

```sh
GITHUB_TOKEN=$(gh auth token) nix develop .#default --command bash scripts/update.sh
nix flake check -L
```

Or trigger the workflow: `gh workflow run update.yml -R Devitek/elegoo-slicer-nixos`.
