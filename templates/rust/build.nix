{ inputs, ... }: {
  perSystem = { system, ... }:
    let
      rustFlake = inputs.flake-lang.lib.${system}.rustFlake {
        src = ./.;
        crateName = "example";
      };
    in
    {
      inherit (rustFlake) packages checks devShells;
    };
}
