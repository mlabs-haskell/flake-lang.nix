# Creates a haskell.nix module that prepares a Cabal environment for building with Plutus.
compiler-nix-name: cardano-haskell-packages:
{ lib, config, pkgs, ... }:
let
  pkgs' = pkgs;
  module = _: {
    _file = "flake-lang.nix/flake-lang/haskell.nix/plutus.nix:module";
    # FIXME: contentAddressed = true;
    reinstallableLibGhc = false; # See https://github.com/input-output-hk/haskell.nix/issues/1939
  };
in
{
  _file = "flake-lang.nix/flake-lang/haskell.nix/plutus.nix";
  config = {
    cabalProjectLocal = builtins.readFile ./cabal.project.local;
    inherit compiler-nix-name;
    modules = [ module ];
    inputMap."https://input-output-hk.github.io/cardano-haskell-packages" = "${cardano-haskell-packages}";
    shell = {
      withHoogle = lib.mkOverride 999 false; # FIXME set to true
      exactDeps = lib.mkOverride 999 true;
      tools.haskell-language-server = { };
      # We use the ones from Nixpkgs, since they are cached reliably.
      # Eventually we will probably want to build these with haskell.nix.
      nativeBuildInputs = [
        pkgs'.cabal-install
      ];
    };
  };
}
