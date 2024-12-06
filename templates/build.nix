{
  flake = {
    templates = {
      haskell = {
        path = ./haskell;
        description = "A simple GHC/Cabal project using flake-lang.nix";
      };
      rust = {
        path = ./rust;
        description = "A simple Rust/Cargo project using flake-lang.nix";
      };
      rust-monorepo = {
        path = ./rust-monorepo;
        description = "A project consists of multiple rust crates using flake-lang.nix";
      };
      typescript = {
        path = ./typescript;
        description = "A Typescript/NPM project using flake-lang.nix";
      };
    };
  };
}
