_: {
  perSystem =
    {
      pkgs,
      config,
      ...
    }:

    let
      pursFlake = config.lib.purescriptFlake {
        inherit pkgs;
        src = ./.;
        projectName = "purescript-flake-project";
        strictComp = true;
        packageJson = ./package.json;
        packageLock = ./package-lock.json;
        shell = {
          withRuntime = false;
          packageLockOnly = true;
          packages = [
            pkgs.nodejs
            pkgs.bashInteractive
            pkgs.fd
          ];
        };
      };
    in
    {

      devShells.purescript-flake-project = pursFlake.devShell;
      inherit (pursFlake) packages checks;

    };
}
