<p align="center">
  <img src=".github/assets/banner.svg" alt="elegoo-slicer-nixos" width="100%">
</p>

<p align="center">ElegooSlicer for NixOS, kept in sync with upstream releases.</p>

<p align="center">
  <a href="https://github.com/Devitek/elegoo-slicer-nixos/releases/latest"><img src="https://img.shields.io/github/v/release/Devitek/elegoo-slicer-nixos?style=flat-square&label=release&labelColor=141517&color=F0703A" alt="Latest release"></a>
  <a href="https://github.com/Devitek/elegoo-slicer-nixos/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Devitek/elegoo-slicer-nixos/ci.yml?branch=main&style=flat-square&label=ci&labelColor=141517" alt="CI"></a>
  <a href="https://github.com/elegooofficial/ElegooSlicer/releases"><img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FDevitek%2Felegoo-slicer-nixos%2Fmain%2F_sources%2Fgenerated.json&query=%24%5B%22elegoo-slicer%22%5D.version&style=flat-square&label=ElegooSlicer&labelColor=141517&color=F6F5F2" alt="Packaged ElegooSlicer version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Devitek/elegoo-slicer-nixos?style=flat-square&labelColor=141517&color=F6F5F2" alt="License"></a>
</p>

<p align="center">
  <a href="#installation">Installation</a> ·
  <a href="#usage">Usage</a> ·
  <a href="#documentation">Documentation</a> ·
  <a href="CHANGELOG.md">Changelog</a> ·
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

[ElegooSlicer](https://github.com/elegooofficial/ElegooSlicer) is Elegoo's open-source FDM slicer, an OrcaSlicer fork. This repository repackages its official Linux AppImage for NixOS, with a desktop entry, file associations and declarative install. New upstream releases are picked up, built, smoke-tested and merged automatically.

> [!NOTE]
> Community project, not affiliated with or endorsed by Elegoo. Slicer bugs belong [upstream](https://github.com/elegooofficial/ElegooSlicer/issues); packaging bugs belong [here](https://github.com/Devitek/elegoo-slicer-nixos/issues).

## Installation

Try it without installing anything:

```sh
nix run github:devitek/elegoo-slicer-nixos
```

Or add the flake to your inputs:

```nix
{
  inputs.elegoo-slicer.url = "github:devitek/elegoo-slicer-nixos";
  inputs.elegoo-slicer.inputs.nixpkgs.follows = "nixpkgs"; # optional
}
```

Supports `x86_64-linux`, the only Linux build upstream publishes. The 3D preview needs OpenGL, so enable `hardware.graphics.enable = true;` on NixOS.

## Usage

**NixOS**

```nix
{
  imports = [ elegoo-slicer.nixosModules.default ];
  programs.elegoo-slicer.enable = true;
}
```

**Home Manager**

```nix
{
  imports = [ elegoo-slicer.homeManagerModules.default ];
  programs.elegoo-slicer.enable = true;
}
```

**Overlay**

```nix
nixpkgs.overlays = [ elegoo-slicer.overlays.default ];
# then: pkgs.elegoo-slicer
```

## How updates work

[nvfetcher](https://github.com/berberman/nvfetcher) tracks upstream releases. When a new one lands, the update workflow refreshes the version and hash, runs `nix flake check` (build, smoke test, module evaluation) and merges the change. [release-please](https://github.com/googleapis/release-please) then cuts a SemVer release of this repository. Pin a tag if you prefer to update on your own schedule.

<details>
<summary><strong>Troubleshooting</strong></summary>

**`HTTP error 403` when fetching the flake.** Fetch over git instead of the GitHub API:

```sh
nix run 'git+https://github.com/devitek/elegoo-slicer-nixos'
```

</details>

## Documentation

- [Functional overview](docs/functional.md)
- [Technical architecture](docs/technical.md)
- [Architecture Decision Records](docs/adr/)

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first: one issue per change, Conventional Commits, green CI.

## License

The packaging code is released under the [MIT License](LICENSE). ElegooSlicer itself remains under its upstream license (AGPL-3.0).

---

<p align="center">
  <a href="https://github.com/Devitek">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset=".github/assets/devitek-wordmark-blanc.svg">
      <img src=".github/assets/devitek-wordmark-encre.svg" alt="Devitek" height="22">
    </picture>
  </a>
  <br>
  <sub>Built and maintained by <a href="https://github.com/Devitek">Devitek</a></sub>
</p>
