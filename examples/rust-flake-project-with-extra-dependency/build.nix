{ ... }: {
  perSystem = { config, ... }:

    let
      rustFlake = config.lib.rustFlake
        {
          src = ./.;
          crateName = "rust-flake-project-with-extra-dependency";

          extraSources = [
            config.packages.rust-flake-project-rust-src
          ];

          devShellHook = config.settings.shell.hook;

          extraSourceFilters = [
            # Include Markdown files in sources
            (path: _type: builtins.match ".*md$" path != null)
          ];

        };
    in
    {

      inherit (rustFlake) packages checks devShells;

    };
}
