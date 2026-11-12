# nixpkgs overlay exposing ElegooSlicer as `pkgs.elegoo-slicer`.
#
#   nixpkgs.overlays = [ elegoo-slicer.overlays.default ];
#   environment.systemPackages = [ pkgs.elegoo-slicer ];
final: _prev: {
  inherit (import ../pkgs { pkgs = final; }) elegoo-slicer;
}
