inputs:
inputs.flake-parts.lib.mkFlake { inherit inputs; } (
  {
    withSystem,
    flake-parts-lib,
    lib,
    config,
    ...
  }:
  {
    systems = import inputs.systems.outPath;

    imports = [
      inputs.flake-file.flakeModules.default
    ];

    flake-file = {
      nixConfig = {
        commit-lockfile-summary = "chore(flake): update `flake.lock`";
        extra-experimental-features = [
          "pipe-operators"
        ];
      };

      inputs = {
        systems = {
          url = "github:nix-systems/default";
        };

        nixpkgs = {
          url = "github:nixos/nixpkgs/nixos-unstable";
        };

        flake-file = {
          url = "github:vic/flake-file";
        };

        flake-parts = {
          url = "github:hercules-ci/flake-parts";
          inputs.nixpkgs-lib.follows = "nixpkgs";
        };
      };
    };

    debug = true;

    perSystem =
      {
        lib,
        pkgs,
        system,
        inputs',
        self',
        ...
      }:
      let
        fs = lib.fileset;
      in
      {
        packages.default = pkgs.python3Packages.buildPythonApplication (finalAttrs: {
          pname = "dlopen-resolver";
          version = "0.0.1";
          pyproject = false;

          src = fs.toSource rec {
            root = ./.;
            fileset = lib.path.append root "dlopen-resolver.py";
          };

          dependencies = with pkgs.python3Packages; [
            intervaltree
            r2pipe
          ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            install -m755 -D dlopen-resolver.py $out/bin/${finalAttrs.pname}

            runHook postInstall
          '';

          installCheckPhase = ''
            runHook preInstallCheck

            $CC -ldl -o main ${./main.c}
            $out/bin/${finalAttrs.pname} main | grep libfoo | wc -l | grep -q 3

            runHook postInstallCheck
          '';

          meta.mainProgram = finalAttrs.pname;
        });
      };
  }
)
