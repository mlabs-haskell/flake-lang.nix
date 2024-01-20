# Note(jaredponn): 

# Loosely, the key idea is that in this flake we want to have an attribute like
# ```
# lib.<system> = {
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
    flake = flake-parts-lib.mkSubmoduleOptions {
      lib = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf (lib.types.functionTo lib.types.attrs));
        default = { };
        visible = false;
      };
    };
    perSystem = flake-parts-lib.mkPerSystemOption ({ pkgs, pkgsForCtl, pkgsForHaskellNix, pkgsForRust, ... }: {
      options = {
        lib = {
          purescriptFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.attrs;
            default = import ./flake-purescript.nix pkgsForCtl;
            readOnly = true;
            description = lib.mdDoc ''
              TODO(jaredponn): write down documentation here
            '';
            example = lib.mdDoc ''
              TODO(jaredponn): write down an example here
            '';
          };

          rustFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.attrs;
            default = import ./flake-rust.nix pkgsForRust;
            readOnly = true;
            description = lib.mdDoc ''
              TODO(jaredponn): write down documentation here
            '';
            example = lib.mdDoc ''
              TODO(jaredponn): write down an example here
            '';
          };

          haskellFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.attrs;
            default = import ./flake-haskell.nix pkgsForHaskellNix;
            readOnly = true;
            description = lib.mdDoc ''
              TODO(jaredponn): write down documentation here
            '';
            example = lib.mdDoc ''
              TODO(jaredponn): write down an example here
            '';
          };

          haskellPlutusFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.attrs;
            default = import ./flake-haskell-plutus.nix inputs.cardano-haskell-packages pkgsForHaskellNix;
            readOnly = true;
            description = lib.mdDoc ''
              TODO(jaredponn): write down documentation here
            '';
            example = lib.mdDoc ''
              TODO(jaredponn): write down an example here
            '';
          };

          typescriptFlake = lib.mkOption {
            type = lib.types.functionTo lib.types.attrs;
            default = import ./flake-typescript.nix pkgs;
            readOnly = true;
            description = lib.mdDoc ''
              TODO(jaredponn): write down documentation here
            '';
            example = lib.mdDoc ''
              TODO(jaredponn): write down an example here
            '';
          };

        };
      };
    });
  };

  config = {
    # TODO(jaredponn): not sure why the new fancy `transposition` submodule
    # doesn't set the `perInput` correctly? So, when consuming this module, we
    # can't do something like
    # ```
    # inputs'.flake-lang.lib.haskellFlake { ... }
    # ```
    # and instead must do
    # ```
    # inputs.flake-lang.lib.${system}.haskellFlake { ... }
    # ```
    transposition.lib = { };
  };
}
