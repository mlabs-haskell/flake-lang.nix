{ lib, ... }: {
  perSystem = { config, pkgs, ... }:

    let
      inherit (builtins) mapAttrs;
      inherit (lib) mapAttrs' nameValuePair mkIf;
      inherit (pkgs.stdenv) isLinux;

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
    {
      imports = [
        {
          inherit (rustFlake) packages checks devShells;
        }
        (mkIf isLinux {
          inherit (rustFlakeMusl') packages checks devShells;
        })
      ];
    };
}
