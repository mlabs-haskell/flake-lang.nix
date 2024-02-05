# The projects in this directory test if the nix utilities' produced
# derivations (i.e., the derivations in `.checks`, `.packages`, `.devShell`)
# can be built with a simple project for each language.
_:
{
  imports =
    [
      ./haskell-flake-project/build.nix
      ./rust-flake-project/build.nix
      ./typescript-flake-project/build.nix
      ./typescript-flake-project-with-extra-dependency/build.nix
      ./typescript-flake-project-with-transitive-extra-dependency/build.nix
    ];
}
