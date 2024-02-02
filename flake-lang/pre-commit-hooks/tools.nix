{ flake-parts-lib, lib, ... }: {
  perSystem = flake-parts-lib.mkPerSystemOption ({ pkgs, pkgsForRust, ... }: {
    options = {
      flake-lang.pre-commit-hooks.tools = {

        rustfmt = lib.mkOption {
          type = lib.types.derivation;
          default = pkgsForRust.rustfmt;
          readOnly = false;
          description = lib.mdDoc ''Rust formatter to use for pre-commit hooks'';
        };

        deno = lib.mkOption {
          type = lib.types.derivation;
          default = pkgs.deno;
          readOnly = false;
          description = lib.mdDoc ''Deno tool to use for pre-commit hooks'';
        };

      };
    };
  });
}
