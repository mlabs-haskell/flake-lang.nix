{
  description = "Tools for generating flakes";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    # Haskell

    ## Using haskell.nix to build Haskell projects
    haskell-nix.url = "github:input-output-hk/haskell.nix";

    # Nix

    ## Flakes as modules, using this extensively to organize the repo into modules (build.nix files)
    flake-parts.url = "github:hercules-ci/flake-parts";

    ## Code quality automation
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    ## Hercules CI effects
    hci-effects.url = "github:hercules-ci/hercules-ci-effects";

    # Purescript

    ## Cardano transaction library (leveraging CTL's Purescript Nix machinery)
    ctl = {
      url = "github:plutonomicon/cardano-transaction-lib?ref=develop";
      inputs.db-sync.follows = "db-sync-ctl";
    };

    db-sync-ctl = {
      inputs.haskellNix.follows = "haskell-nix";
      url = "github:input-output-hk/cardano-db-sync/13.1.1.3";
    };


    # Rust

    crane.url = "github:ipetkov/crane";
    rust-overlay.url = "github:oxalica/rust-overlay";

    # Plutus

    ## CHaP is a custom hackage for Plutus development
    cardano-haskell-packages.url = "github:input-output-hk/cardano-haskell-packages?ref=repo";
    cardano-haskell-packages.flake = false;

    ## Some crypto overlays necessary for Plutus
    iohk-nix.url = "github:input-output-hk/iohk-nix";

    ## Foundational Plutus library
    plutus.url = "github:input-output-hk/plutus";

    ## Plutarch eDSL
    plutarch = {
      url = "github:plutonomicon/plutarch-plutus";
      flake = false;
    };

  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ flake-parts-lib, withSystem, ... }: {
      systems = [ "x86_64-linux" "x86_64-darwin" ];

      imports = [
        # Project configuration
        ./pkgs.nix
        ./settings.nix

        # Code quality
        (flake-parts-lib.importApply ./flake-lang/pre-commit-hooks/rust-monorepo.nix { inherit withSystem; })
        ./pre-commit.nix
        ./hercules-ci.nix

        # Nix tools
        ./flake-lang/build.nix

        # Examples/Tests
        ./examples/build.nix
        # Documentation
        ./docs/build.nix
      ];
    });
}
