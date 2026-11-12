# NixOS module: install ElegooSlicer system-wide.
#
#   imports = [ elegoo-slicer.nixosModules.default ];
#   programs.elegoo-slicer.enable = true;
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
      description = ''
        The ElegooSlicer package to install. Override to pin a different revision of
        this flake. The desktop entry and icon are integrated automatically.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # The 3D preview is OpenGL; it needs a working graphics stack.
    warnings = lib.optional (!config.hardware.graphics.enable) ''
      programs.elegoo-slicer is enabled but hardware.graphics.enable is false.
      ElegooSlicer needs OpenGL drivers at runtime; set
      `hardware.graphics.enable = true;`.
    '';
  };
}
