# Functional overview

## What this is

`elegoo-slicer-nixos` makes [**ElegooSlicer**](https://github.com/elegooofficial/ElegooSlicer),
Elegoo's open-source FDM slicer (an OrcaSlicer fork), installable on NixOS the way
NixOS users expect: declaratively, reproducibly, and always up to date. It
repackages the official Linux AppImage; it does not fork or rebuild the slicer.

It is **unofficial** and not affiliated with or endorsed by Elegoo.

## Who it's for

- NixOS users who want ElegooSlicer in `configuration.nix`.
- Home Manager users who want it per-user.
- Anyone who wants to try it with a single `nix run`.

## What you get

- The `elegoo-slicer` command, a desktop entry ("ElegooSlicer") and its icon.
- File associations from upstream: STL, 3MF, OBJ, AMF.
- The full upstream feature set, including Elegoo printer discovery on the LAN and
  the Elegoo cloud services, since the binary is the one upstream ships.

## What the flake provides

- `packages.x86_64-linux.elegoo-slicer` (also `default`).
- `apps.x86_64-linux.elegoo-slicer` (also `default`): `nix run` entry point.
- `overlays.default`: adds `pkgs.elegoo-slicer`.
- `nixosModules.default`: `programs.elegoo-slicer` for system-wide installs.
- `homeManagerModules.default`: `programs.elegoo-slicer` for per-user installs.
- `devShells.default`, `formatter`, and `checks` (headless smoke test + module
  evaluations).

Supported system: `x86_64-linux` only, the single Linux build upstream publishes
([ADR-0002](adr/0002-target-platforms.md)).

## Staying up to date

When Elegoo publishes a release, the update workflow picks it up, checks that it
builds and starts, and merges it automatically. Each change to this repository is
then released as a SemVer tag. Pin a tag or commit of this flake if you prefer to
update on your own schedule.

See the [technical documentation](technical.md) for how it all fits together.
