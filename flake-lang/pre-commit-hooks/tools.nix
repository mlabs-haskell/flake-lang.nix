localFlake:
{ flake-parts-lib, lib, ... }:
{
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption (
      { system, ... }:
      {
        options = {
          flake-lang.pre-commit-hooks.tools = {
            rustfmt = lib.mkOption {
              type = lib.types.package;
              default = localFlake.withSystem system ({ inputs', ... }: inputs'.rust-overlay.packages.rust);
              readOnly = false;
              description = ''Rust formatter to use for pre-commit hooks'';
            };
          };
        };
      }
    );
  };
}
