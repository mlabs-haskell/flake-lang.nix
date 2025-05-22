{ inputs, ... }:
{
  imports = [
    inputs.pre-commit-hooks.flakeModule
    inputs.flake-lang.flakeModules.rustMonorepoPreCommit
  ];

  perSystem =
    { config, ... }:
    {
      pre-commit.settings.hooks = {
        nixfmt-rfc-style.enable = true;
        deadnix.enable = true;
        rustfmt-monorepo.enable = true;
        typos.enable = true;
      };

      devShells.dev-pre-commit = config.pre-commit.devShell;
    };
}
