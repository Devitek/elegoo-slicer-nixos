# Home Manager module: install ElegooSlicer for a single user.
#
#   imports = [ elegoo-slicer.homeManagerModules.default ];
#   programs.elegoo-slicer.enable = true;
#
# The 3D preview still requires a working system graphics stack
# (`hardware.graphics.enable = true;` on NixOS).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.elegoo-slicer;
in
{
  options.programs.elegoo-slicer = {
    enable = lib.mkEnableOption "ElegooSlicer, Elegoo's FDM slicer";

    package = lib.mkOption {
      type = lib.types.package;
      default = (import ../pkgs { inherit pkgs; }).elegoo-slicer;
      defaultText = lib.literalMD "ElegooSlicer from this flake";
      description = "The ElegooSlicer package to install into the user environment.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
