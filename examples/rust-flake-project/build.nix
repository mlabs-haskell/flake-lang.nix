{ ... }: {
  perSystem = { config, ... }:

    let
      rustFlake = config.lib.rustFlake
        {
          src = ./.;
          crateName = "rust-flake-project";

          devShellHook = config.settings.shell.hook;

        };
    in
    {

      inherit (rustFlake) packages checks devShells;

    };
}
