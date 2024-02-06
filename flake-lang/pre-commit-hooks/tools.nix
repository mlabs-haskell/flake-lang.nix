{ flake-parts-lib, lib, ... }: {
  imports = [ ../../pkgs.nix ];
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption ({ config, ... }: {
      options = {
        flake-lang.pre-commit-hooks.tools = {
          rustfmt = lib.mkOption {
            type = lib.types.package;
            default = config.flake-lang-pkgs.pkgsForRust.rustfmt;
            readOnly = false;
            description = lib.mdDoc ''Rust formatter to use for pre-commit hooks'';
          };
        };
      };
    });
  };
}
