{ inputs, ... }: {
  imports = [
    inputs.pre-commit-hooks.flakeModule
  ];
  perSystem = { config, ... }: {
    devShells.default = config.pre-commit.devShell;
    pre-commit.settings = {
      hooks = {
        # Typos
        typos.enable = true;

        # Markdown
        markdownlint.enable = true;

        # Nix
        nixpkgs-fmt.enable = true;
        deadnix.enable = true;

        # Haskell
        cabal-fmt.enable = true;
        hlint.enable = true;
        fourmolu.enable = true;

        # Typescript
        denofmt = {
          enable = true;
          # NOTE(jaredponn): We follow the default files deno formats, except
          # we exclude markdown files. See:
          #   [1] https://docs.deno.com/runtime/manual/tools/formatter
          files = ''^.*\.(js|ts|jsx|tsx|json|jsonc)$'';
        };
        denolint.enable = true;

        # Rust
        rustfmt-monorepo.enable = true;
      };
    };
  };
}
