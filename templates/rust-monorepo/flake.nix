{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-lang.url = "github:mlabs-haskell/flake-lang.nix";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
      ];

      imports = [
        ./example/build.nix
        ./settings.nix
        ./pre-commit.nix
      ];

      perSystem = { config, ... }: {
        devShells.default = config.devShells.dev-pre-commit;
      };
    };
}
