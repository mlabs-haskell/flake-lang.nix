# Repo-wide Nixpkgs with different overlays
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let

      overlays = {
        purescript = final: _: {
          easy-ps = import inputs.easy-purescript-nix { pkgs = final; };
          purescriptProject = import ./nix { pkgs = final; };
        };
        spago = final: prev: {
          easy-ps = prev.easy-ps // {
            spago = prev.easy-ps.spago.overrideAttrs (_: rec {
              version = "0.21.0";
              src =
                if final.stdenv.isDarwin then
                  final.fetchurl {
                    url = "https://github.com/purescript/spago/releases/download/${version}/macOS.tar.gz";
                    sha256 = "19c0kdg7gk1c7v00lnkcsxidffab84d50d6l6vgrjy4i86ilhzd5";
                  }
                else
                  final.fetchurl {
                    url = "https://github.com/purescript/spago/releases/download/${version}/Linux.tar.gz";
                    sha256 = "1klczy04vwn5b39cnxflcqzap0d5kysp4dsw73i95xm5m7s37049";
                  };
            });
          };
        };
      };
    in
    {

      _module.args = {
        pkgs = import inputs.nixpkgs {
          inherit system;
        };

        pkgsForCtl = import inputs.nixpkgs {
          inherit system;
          inherit (inputs.haskell-nix) config;
          overlays = [
            inputs.haskell-nix.overlay
            inputs.iohk-nix.overlays.crypto
            inputs.iohk-nix.overlays.haskell-nix-crypto
            overlays.purescript
            overlays.spago
          ];
        };

        # TODO(bladyjoker): haskell.nix is brittle on its nixpkgs, and tends to break stuff for us, so we instantiate haskell.nix nixpkgs specifically. For example https://github.com/Plutonomicon/plutarch-plutus/pull/624
        pkgsForHaskellNix = import inputs.haskell-nix.inputs.nixpkgs {
          inherit system;
          inherit (inputs.haskell-nix) config;
          overlays = [
            inputs.haskell-nix.overlay
            inputs.iohk-nix.overlays.crypto
            inputs.iohk-nix.overlays.haskell-nix-crypto
          ];
        };

        pkgsForRust = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (import inputs.rust-overlay)
          ];
        };
      };
    };
}
