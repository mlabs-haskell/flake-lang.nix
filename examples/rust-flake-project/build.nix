{ inputs, ... }: {
  perSystem = { config, ... }:

    let
      rustFlake = config.lib.rustFlake
        {
          src = ./.;
          inherit (inputs) crane;
          crateName = "rust-flake-test";

          devShellHook = config.settings.shell.hook;

        };
    in
    {

      inherit (rustFlake) packages checks devShells;

    };
}
