{
  description = "nix runner";

  nixConfig = {
    extra-substituters = [
      "https://cache.trev.zip/nur"
    ];
    extra-trusted-public-keys = [
      "nur:70xGHUW1+1b8FqBchldaunN//pZNVo6FKuPL4U/n844="
    ];
  };

  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    trev = {
      url = "github:spotdemo4/nur";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      trev,
      ...
    }:
    trev.libs.mkFlake (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            trev.overlays.packages
            trev.overlays.libs
          ];
        };
        fs = pkgs.lib.fileset;
      in
      {
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # formatters
              nixfmt
              prettier
              renovate

              # util
              bumper
            ];
            shellHook = pkgs.shellhook.ref;
          };

          bump = pkgs.mkShell {
            packages = with pkgs; [
              bumper
            ];
          };

          update = pkgs.mkShell {
            packages = with pkgs; [
              renovate
            ];
          };

          vulnerable = pkgs.mkShell {
            packages = with pkgs; [
              # nix
              flake-checker

              # actions
              octoscan
            ];
          };
        };

        checks = pkgs.lib.mkChecks {
          actions = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.unions [
                ./.github/workflows
              ];
            };
            deps = with pkgs; [
              action-validator
              octoscan
            ];
            script = ''
              action-validator **/*.yaml
              octoscan scan .
            '';
          };

          docker = {
            src = fs.toSource {
              root = ./.;
              fileset = ./Dockerfile;
            };
            deps = with pkgs; [
              hadolint
            ];
            script = ''
              hadolint Dockerfile
            '';
          };

          renovate = {
            src = fs.toSource {
              root = ./.github;
              fileset = ./.github/renovate.json;
            };
            deps = with pkgs; [
              renovate
            ];
            script = "renovate-config-validator renovate.json";
          };

          nix = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.fileFilter (file: file.hasExt "nix") ./.;
            };
            deps = with pkgs; [
              nixfmt-tree
            ];
            script = ''
              treefmt --ci
            '';
          };

          prettier = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.fileFilter (file: file.hasExt "yaml" || file.hasExt "json" || file.hasExt "md") ./.;
            };
            deps = with pkgs; [
              prettier
            ];
            script = ''
              prettier --check .
            '';
          };
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
