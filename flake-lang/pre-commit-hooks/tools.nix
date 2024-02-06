{ flake-parts-lib, lib, ... }: {
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption ({ inputs', ... }: {
      options = {
        flake-lang.pre-commit-hooks.tools = {
          rustfmt = lib.mkOption {
            type = lib.types.package;
            default = inputs'.rust-overlay.packages.rust;
            readOnly = false;
            description = lib.mdDoc ''Rust formatter to use for pre-commit hooks'';
          };
        };
      };
    });
  };
}
