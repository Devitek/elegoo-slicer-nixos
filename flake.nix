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

      checks = forAllSystems (
        { pkgs, ... }:
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
        in
        {
          elegoo-slicer-smoke = smoke;
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
