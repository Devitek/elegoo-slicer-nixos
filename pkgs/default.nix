# Package set. The upstream source (version + AppImage url & hash) comes from
# nvfetcher's `_sources/generated.nix`.
{ pkgs }:

let
  sources = pkgs.callPackage ../_sources/generated.nix { };
in
{
  elegoo-slicer = pkgs.callPackage ./elegoo-slicer.nix { source = sources.elegoo-slicer; };
}
