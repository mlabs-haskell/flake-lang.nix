{ inputs, ... }: {
  perSystem = { system, ... }:
    let
      typescriptFlake =
        inputs.flake-lang.lib.${system}.typescriptFlake {
          name = "example";
          src = ./.;
        };
    in
    {
      inherit (typescriptFlake) checks packages;

      # # TODO(chfanghr): Unify the names of dev shells of different languages
      devShells.dev-example-typescript = typescriptFlake.devShells.example-typescript;
    };
}
