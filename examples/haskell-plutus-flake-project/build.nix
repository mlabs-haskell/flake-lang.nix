_: {
  perSystem =
    { config, pkgs, ... }:
    let
      hsFlake = config.lib.haskellPlutusFlake {
        src = ./.;

        name = "haskell-plutus-flake-project";

        inherit (config.settings.haskell) index-state compiler-nix-name;

        devShellTools = config.settings.shell.tools;
        devShellHook = config.settings.shell.hook;
      };

    in

    {
      checks =
        pkgs.lib.attrsets.mapAttrs' (
          k: v: pkgs.lib.attrsets.nameValuePair ("package:${k}") v
        ) hsFlake.packages
        // pkgs.lib.attrsets.mapAttrs' (
          k: v: pkgs.lib.attrsets.nameValuePair ("checks:${k}") v
        ) hsFlake.checks
        // {
          "devShells:haskell-plutus-flake-project" = hsFlake.devShells.default;
        };

      devShells.dev-haskell-plutus-flake-project = hsFlake.devShells.default;
    };
}
