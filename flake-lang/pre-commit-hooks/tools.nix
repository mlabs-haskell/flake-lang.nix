{ flake-parts-lib, lib, ... }: {
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption ({ pkgsForRust, ... }: {
      options = {
        flake-lang.pre-commit-hooks.tools = {
          rustfmt = lib.mkOption {
            type = lib.types.package;
            default = pkgsForRust.rustfmt;
            readOnly = false;
            description = lib.mdDoc ''Rust formatter to use for pre-commit hooks'';
          };
        };
      };
    });
  };
}
