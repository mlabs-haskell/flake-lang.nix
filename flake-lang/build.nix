# Note(jaredponn): 

# Loosely, the key idea is that in this flake we want to have an attribute like
# ```
# lbf-nix.<system> = {
#   haskellFlake = ...
#   rustFlake = ...
#   typescriptFlake = ...
#   ...
# };
# ```
# This is unfortunately not super easy to do with flake-parts! Some useful
# links + examples are as follows. 
# - [1] https://github.com/hercules-ci/flake-parts/blob/main/lib.nix
# - [2] https://github.com/hercules-ci/flake-parts/pull/63/files
# - [3] https://github.com/hercules-ci/flake-parts/blob/main/modules/formatter.nix

{ config, inputs, flake-parts-lib, lib, ... }: {
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption ({ pkgs, pkgsForCtl, pkgsForHaskellNix, pkgsForRust, ... }: {
      options = {
        lib = {
          purescriptFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.raw;
            default = import ./flake-purescript.nix pkgsForCtl;
            readOnly = true;
            description = ''
              TODO(jaredponn): write down documentation here
            '';
          };

          rustFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.raw;
            default = import ./flake-rust.nix pkgsForRust;
            readOnly = true;
            description = ''
              TODO(jaredponn): write down documentation here
            '';
          };

          haskellFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.raw;
            default = import ./flake-haskell.nix pkgsForHaskellNix;
            readOnly = true;
            description = ''
              TODO(jaredponn): write down documentation here
            '';
          };

          haskellPlutusFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.raw;
            default = import ./flake-haskell-plutus.nix inputs.cardano-haskell-packages pkgsForHaskellNix;
            readOnly = true;
            description = ''
              TODO(jaredponn): write down documentation here
            '';
          };

          typescriptFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.raw;
            default = import ./flake-typescript.nix pkgs;
            readOnly = true;
            description = ''
              TODO(jaredponn): write down documentation here
            '';
          };

        };
      };
    });
  };

  config = {
    transposition.lib = { };
  };

}
