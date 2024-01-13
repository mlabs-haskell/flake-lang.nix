{ ... }:
{
  perSystem = { config, ... }:
    let
      typescriptFlake =
        config.lib.typescriptFlake {
          name = "typescript-flake-project";
          src = ./.;

          devShellTools = config.settings.shell.tools;
          devShellHook = config.settings.shell.hook;

          npmExtraDependencies = [ ];
        };
    in
    {
      packages = {
        inherit (typescriptFlake.packages)
          typescript-flake-project-typescript
          typescript-flake-project-typescript-tgz
          typescript-flake-project-typescript-node2nix;
      };

      inherit (typescriptFlake) checks devShells;
    };

}
