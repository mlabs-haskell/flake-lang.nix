localFlake: { inputs, flake-parts-lib, ... }: {
  imports = [
    inputs.pre-commit-hooks.flakeModule # Adds perSystem.pre-commit options
    (flake-parts-lib.importApply ./tools.nix localFlake)
  ];
  perSystem = { config, ... }:
    {
      pre-commit.settings.hooks = {
        rustfmt-monorepo =
          {
            name = "rustfmt";
            description = "Format Rust code.";
            entry = "${config.flake-lang.pre-commit-hooks.tools.rustfmt}/bin/rustfmt --color always";
            files = "\\.rs$";
          };

      };
    };
}
