{ ... }:
{
  perSystem =
    { config, ... }:

    let
      rustFlake = config.lib.rustFlake {
        src = ./.;
        crateName = "rust-flake-project";

        devShellHook = config.settings.shell.hook;
        exportTests = true;
      };
    in
    {

      inherit (rustFlake) packages checks devShells;

    };
}
