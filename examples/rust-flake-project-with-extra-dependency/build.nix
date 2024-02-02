{ inputs, ... }: {
  perSystem = { config, ... }:

    let
      rustFlake = config.lib.rustFlake
        {
          src = ./.;
          inherit (inputs) crane;
          crateName = "rust-flake-project-with-extra-dependency";

          extraSources = [
            config.packages.rust-flake-project-rust-src
          ];

          devShellHook = config.settings.shell.hook;

        };
    in
    {

      inherit (rustFlake) packages checks devShells;

    };
}
