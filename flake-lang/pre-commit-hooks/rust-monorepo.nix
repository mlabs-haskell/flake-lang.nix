{ inputs, ... }: {
  imports = [
    inputs.pre-commit-hooks.flakeModule # Adds perSystem.pre-commit options
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
