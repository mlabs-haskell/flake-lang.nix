{ inputs, ... }:
{
  perSystem =
    { system, config, ... }:
    let
      hsFlake = inputs.flake-lang.lib.${system}.haskellFlake {
        src = ./.;
        name = "example";
        inherit (config.settings.haskell) index-state compiler-nix-name;
      };
    in
    {
      inherit (hsFlake) packages checks;

      # TODO(chfanghr): Unify the names of dev shells of different languages
      devShells.dev-example-haskell = hsFlake.devShell;
    };
}
