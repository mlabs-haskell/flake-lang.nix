{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      typescriptFlake = config.lib.typescriptFlake {
        name = "typescript-flake-project-with-transitive-extra-dependency";
        src = ./.;

        devShellTools = config.settings.shell.tools;
        devShellHook = config.settings.shell.hook;

        npmExtraDependencies = [
          config.packages.typescript-flake-project-with-extra-dependency-typescript-lib
        ];
      };
    in
    {
      packages = {
        inherit (typescriptFlake.packages)
          typescript-flake-project-with-transitive-extra-dependency-typescript
          typescript-flake-project-with-transitive-extra-dependency-typescript-exe
          typescript-flake-project-with-transitive-extra-dependency-typescript-lib
          typescript-flake-project-with-transitive-extra-dependency-typescript-tgz
          typescript-flake-project-with-transitive-extra-dependency-typescript-node2nix
          ;
      };

      inherit (typescriptFlake) devShells;

      checks = {
        inherit (typescriptFlake.checks)
          typescript-flake-project-with-transitive-extra-dependency-typescript-test
          ;

        # Quick derivation to verify that the executable (see the `bin` key of
        # `package.json`) really works.
        typescript-flake-project-with-transitive-extra-dependency-typescript-valid-exe =
          pkgs.runCommand "typescript-flake-project-with-transitive-extra-dependency-typescript-valid-exe"
            {
              buildInputs = [
                config.packages.typescript-flake-project-with-transitive-extra-dependency-typescript-exe
              ];
            }
            ''
              typescript-flake-project-with-transitive-extra-dependency
              touch "$out"
            '';
      };
    };
}
