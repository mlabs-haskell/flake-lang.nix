{ inputs, config, ... }: {
  imports = [
    inputs.pre-commit-hooks.flakeModule
    config.flake-lang.rustMonorepoPreCommit
    config.flake-lang.denoPreCommit
  ];
  perSystem = _: {
    pre-commit.settings = {
      hooks = {
        rust-monorepo.enable = true;
        my-deno.enable = true;
      };
    };
  };
}
