# Repo wide settings
{ lib, flake-parts-lib, ... }: {
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption
      ({ config, ... }: {
        options.settings = {
          haskell = {
            index-state = lib.mkOption {
              type = lib.types.str;
              description = "Hackage index state to use when making a haskell.nix build environment";
            };

            compiler-nix-name = lib.mkOption {
              type = lib.types.str;
              description = "GHC Haskell compiler to use when building haskell.nix projects";
            };
          };
        };


        config = {
          settings = {
            haskell = {
              index-state = "2024-11-13T00:00:00Z";
              compiler-nix-name = "ghc966";
            };
          };
        };
      });
  };
}
