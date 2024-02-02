{ inputs, ... }: {
  imports = [
    inputs.pre-commit-hooks.flakeModule # Adds perSystem.pre-commit options
    ./tools.nix
  ];
  perSystem = { config, ... }:
    {
      pre-commit.settings.hooks = {
        # TODO(jaredponn): Why do we use our strange version of `denofmt` and
        # `denolint`? The default implemented version in `pre-commit-hooks.nix`
        # is a bit buggy (see
        # https://github.com/cachix/pre-commit-hooks.nix/issues/374), and the
        # latest version of `deno` on nix doesn't allow explicitly applying
        # the formatter to specific files
        my-denofmt =
          {
            name = "denofmt";
            description = "Format Typescript code.";
            entry = "${config.flake-lang.pre-commit-hooks.tools.deno}/bin/deno fmt";
            files = "(\\.m?ts$)|(^tsconfig?(-base)\\.json$)";
          };

        my-denolint =
          {
            name = "denolint";
            description = "Lint Typescript code.";
            entry = "${config.flake-lang.pre-commit-hooks.tools.deno}/bin/deno lint";
            files = "\\.m?ts$";
          };

      };
    };
}
