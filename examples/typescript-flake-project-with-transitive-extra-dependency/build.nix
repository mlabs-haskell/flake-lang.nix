{ ... }:
{
  perSystem = { config, ... }:
    let
      typescriptFlake =
        config.lib.typescriptFlake {
          name = "typescript-flake-project-with-transitive-extra-dependency";
          src = ./.;

          devShellTools = config.settings.shell.tools;
          devShellHook = config.settings.shell.hook;

          npmExtraDependencies = [ config.packages.typescript-flake-project-with-extra-dependency-typescript-tgz ];
        };
    in
    {
      packages = {
        inherit (typescriptFlake.packages)
          typescript-flake-project-with-transitive-extra-dependency-typescript
          typescript-flake-project-with-transitive-extra-dependency-typescript-tgz
          typescript-flake-project-with-transitive-extra-dependency-typescript-node2nix;
      };

      inherit (typescriptFlake) checks devShells;
    };

}
