{
  description = "Unofficial NixOS packaging of ElegooSlicer (elegooofficial)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      # Upstream only publishes a Linux x86_64 AppImage (see docs/adr/0002).
      systems = [ "x86_64-linux" ];

      inherit (nixpkgs) lib;

      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );

      packagesFor = pkgs: import ./pkgs { inherit pkgs; };
    in
    {
      # `.#elegoo-slicer` (also `default`).
      packages = forAllSystems (
        { pkgs, ... }:
        let
          set = packagesFor pkgs;
        in
        set // { default = set.elegoo-slicer; }
      );

      # `nix run .#elegoo-slicer` / `nix run .`
      apps = forAllSystems (
        { pkgs, ... }:
        let
          app = {
            type = "app";
            program = lib.getExe (packagesFor pkgs).elegoo-slicer;
            meta.description = "Run ElegooSlicer";
          };
        in
        {
          elegoo-slicer = app;
          default = app;
        }
      );

      # nixpkgs overlay: adds `pkgs.elegoo-slicer`.
      overlays.default = import ./nix/overlay.nix;

      # System / per-user integration modules.
      nixosModules.default = import ./nix/nixos-module.nix;
      homeManagerModules.default = import ./nix/hm-module.nix;

      checks = forAllSystems (
        { pkgs, system }:
        let
          pkg = (packagesFor pkgs).elegoo-slicer;

          # Headless smoke test: `--help` needs no display, but the binary only gets
          # there if the FHS env resolves every NEEDED library and upstream's launcher
          # finds libOpenGL / WebKitGTK 4.1. That is what breaks on upstream bumps.
          smoke = pkgs.runCommand "elegoo-slicer-smoke" { nativeBuildInputs = [ pkg ]; } ''
            echo "smoke-testing elegoo-slicer ${pkg.version}"
            export HOME="$TMPDIR"
            ${lib.getExe pkg} --help > help.txt 2>&1 || { cat help.txt; exit 1; }
            grep -q '^Usage: elegoo-slicer' help.txt || { cat help.txt; exit 1; }
            head -1 help.txt
            touch "$out"
          '';

          # Evaluate the NixOS module and assert the package lands in
          # environment.systemPackages (no system build required).
          nixosEval =
            let
              sys = lib.nixosSystem {
                modules = [
                  ./nix/nixos-module.nix
                  {
                    nixpkgs.hostPlatform = system;
                    programs.elegoo-slicer.enable = true;
                    boot.loader.grub.enable = false;
                    fileSystems."/" = {
                      device = "nodev";
                      fsType = "tmpfs";
                    };
                    system.stateVersion = "24.05";
                  }
                ];
              };
              ok = builtins.any (p: (p.pname or "") == "elegoo-slicer") sys.config.environment.systemPackages;
            in
            pkgs.runCommand "nixos-module-eval" { } (
              if ok then
                "echo 'elegoo-slicer present in systemPackages' > \"$out\""
              else
                "echo 'elegoo-slicer missing from systemPackages' >&2; exit 1"
            );

          # Evaluate the Home Manager module in isolation (no home-manager input
          # needed): stub home.packages and assert the package lands in it.
          hmEval =
            let
              eval = lib.evalModules {
                specialArgs = { inherit pkgs; };
                modules = [
                  ./nix/hm-module.nix
                  {
                    options.home.packages = lib.mkOption {
                      type = lib.types.listOf lib.types.package;
                      default = [ ];
                    };
                  }
                  { programs.elegoo-slicer.enable = true; }
                ];
              };
              ok = builtins.any (p: (p.pname or "") == "elegoo-slicer") eval.config.home.packages;
            in
            pkgs.runCommand "home-manager-module-eval" { } (
              if ok then
                "echo 'elegoo-slicer present in home.packages' > \"$out\""
              else
                "echo 'elegoo-slicer missing from home.packages' >&2; exit 1"
            );
        in
        {
          elegoo-slicer-smoke = smoke;
          nixos-module = nixosEval;
          home-manager-module = hmEval;
        }
      );

      # Reproducible development shell: Nix tooling + updater + linters.
      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.mkShellNoCC {
            name = "elegoo-slicer-nixos";
            packages = with pkgs; [
              nvfetcher # upstream release tracker + hash generator
              nix-prefetch # fallback hash computation
              jq
              gh
              nixfmt # `nix fmt` (RFC 166 style)
              statix # Nix linter
              deadnix # dead-code finder
              shellcheck
            ];
            shellHook = ''
              echo "elegoo-slicer-nixos devshell — nvfetcher $(nvfetcher --version 2>/dev/null || echo '?')"
            '';
          };
        }
      );

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt);
    };
}
