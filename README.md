# elegoo-slicer-nixos

> Unofficial NixOS packaging of [**ElegooSlicer**](https://github.com/elegooofficial/ElegooSlicer),
> Elegoo's open-source FDM slicer.

[![CI](https://github.com/Devitek/elegoo-slicer-nixos/actions/workflows/ci.yml/badge.svg)](https://github.com/Devitek/elegoo-slicer-nixos/actions/workflows/ci.yml)
[![Auto-update](https://github.com/Devitek/elegoo-slicer-nixos/actions/workflows/update.yml/badge.svg)](https://github.com/Devitek/elegoo-slicer-nixos/actions/workflows/update.yml)

This flake packages ElegooSlicer for NixOS as a Nix **flake**, a **nixpkgs
overlay**, a **NixOS module** and a **Home Manager module**. The package tracks the
official GitHub releases and is refreshed automatically.

> **Disclaimer.** This is a community repository and is **not affiliated with or
> endorsed by** Elegoo. It repackages the official Linux AppImage (AGPL-3.0
> upstream). The packaging code here is MIT-licensed.

## Supported systems

`x86_64-linux` only: upstream publishes a single Linux build, an x86_64 AppImage
([ADR-0002](docs/adr/0002-target-platforms.md)).

The 3D preview needs OpenGL. On NixOS:

```nix
hardware.graphics.enable = true; # NixOS < 24.11: hardware.opengl.enable = true;
```

## Usage

### Try it without installing

```sh
nix run github:devitek/elegoo-slicer-nixos
```

### As a flake input

```nix
{
  inputs.elegoo-slicer.url = "github:devitek/elegoo-slicer-nixos";
  # optional: reuse your own nixpkgs
  inputs.elegoo-slicer.inputs.nixpkgs.follows = "nixpkgs";
}
```

### NixOS module

```nix
{
  imports = [ elegoo-slicer.nixosModules.default ];

  programs.elegoo-slicer.enable = true;

  hardware.graphics.enable = true;
}
```

### Home Manager module

```nix
{
  imports = [ elegoo-slicer.homeManagerModules.default ];

  programs.elegoo-slicer.enable = true;
}
```

### Overlay

```nix
nixpkgs.overlays = [ elegoo-slicer.overlays.default ];
# then: pkgs.elegoo-slicer
```

## How updates work

When Elegoo publishes a release, [`nvfetcher`](https://github.com/berberman/nvfetcher)
picks it up, `_sources/` is refreshed with the new version and hash, the package is
built and smoke-tested, and an auto-merging PR lands it. See
[docs/technical.md](docs/technical.md) and
[ADR-0003](docs/adr/0003-update-mechanism.md).

## Troubleshooting

### `HTTP error 403` when fetching the flake

If fetching `github:devitek/elegoo-slicer-nixos` returns a GitHub API `403`, fetch
over git instead of the REST API, just swap the flake URL:

```sh
nix run 'git+https://github.com/devitek/elegoo-slicer-nixos'
```

### Slicer bugs

This repository only packages ElegooSlicer. Report problems with the slicer itself
[upstream](https://github.com/elegooofficial/ElegooSlicer/issues); report packaging
problems (missing library, desktop entry, module) here.

## Documentation

- [Functional overview](docs/functional.md)
- [Technical architecture](docs/technical.md)
- [Architecture Decision Records](docs/adr/)
- [Contributing](CONTRIBUTING.md)

## License

Packaging code: [MIT](LICENSE). ElegooSlicer itself remains under its upstream
license (AGPL-3.0).
