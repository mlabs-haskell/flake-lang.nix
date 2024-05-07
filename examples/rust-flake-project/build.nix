{ lib, ... }: {
  perSystem = { config, ... }:

    let
      inherit (builtins) mapAttrs;
      inherit (lib) mapAttrs' nameValuePair recursiveUpdate;

      commonArgs = {
        src = ./.;
        crateName = "rust-flake-project";

        devShellHook = config.settings.shell.hook;
      };

      rustFlake = config.lib.rustFlake commonArgs;

      rustFlakeMusl = config.lib.rustFlake (commonArgs // {
        target = "x86_64-unknown-linux-musl";
        extraRustcFlags = "-C target-feature=+crt-static";
      });

      addMuslSuffixToAttrNames = mapAttrs' (name: nameValuePair "${name}-musl");

      rustFlakeMusl' = mapAttrs (_: addMuslSuffixToAttrNames) rustFlakeMusl;
    in
    recursiveUpdate
      {
        inherit (rustFlake) packages checks devShells;
      }
      {
        inherit (rustFlakeMusl') packages checks devShells;
      };
}
