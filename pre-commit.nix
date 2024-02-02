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
      };
    };
  };
}
