<!-- This file is used in `../build.nix`'s `description` for Rust -->

<!-- markdownlint-disable MD041 -->

Creates a flake for a Rust project.

**Arguments:**

- `src`: Source folder (unfiltered)
- `extraSourceFilters`(optional): Extra filters to add non-rust related files to
  the derivation
- `crane`(optional): Crane version to be used
- `crateName`: Name of the project
- `version`: Major version of the project
- `rustChannel`(default=stable): Rust profile (stable, nightly, etc.)
- `rustVersion`(default=latest): Rust version
- `nativeBuildInputs`(optional): Additional native build inputs
- `buildInputs`(optional): Additional build inputs
- `extraSources`(optional): Extra sources, allowing to use other rustFlake components
  to be used as dependencies
- `extraSourcesDir`(default=.extras): Folder to store extra source libraries
- `data`(optional): Data dependencies
- `dataDir`(default=data): Folder to store the data dependencies
- `devShellHook`(optional): Shell script executed after entering the dev shell
- `devShellTools`(optional): Packages made available in the dev shell
- `testTools`(optional): Packages made available in checks and the dev shell
- `cargoNextestExtraArgs`(optional): Extra cargo nextest arguments
- `doInstallCargoArtifacts`(optional): Controls whether cargo's target directory
  should be copied as an output
- `target` (optional): Main Rust compilation target
  (Rust will figure out by default)
- `extraTargets`(optional): Extra Rust compilation targets
- `extraRustcFlags`(optional): Extra rustc flags
- `extraCargoArgs`(optional): Extra cargo arguments
- `extraEnvVars`(optional): Extra environment variables
- `generateDocs`(default=true): Generate Rustdoc
- `runTests`(default=true): Run testsuite using cargo-nextest
- `runClippy`(default=true): Run clippy linter
- `exportTests`(default=false): Build testsuite as standalone executables

**Returns:**

Returns an attribute set of the form

```nix
{
  devShells."dev-${name}-rust" = derivation { ... };
  packages."${name}-rust" = derivation { ... };
  packages."${name}-rust-src" = derivation { ... };
  packages."${name}-rust-build-env" = derivation { ... };
  packages."${name}-rust-doc" = derivation { ... };
  checks."${name}-rust-test" = derivation { ... };
  checks."${name}-rust-clippy" = derivation { ... };
}
```

where

- `packages."${name}-rust"` contains the binary executable of the project.
- `packages."${name}-rust-src"` contains the source folder, to be used as a
  dependency of other application in extraSources
- `packages."${name}-rust-build-env"` contains the source folder, to be used
  as a standalone library (not is extraSources)
- `packages."${name}-rust-doc"` contains the API references document
- `checks."${name}-rust-test"` runs tests using cargo nextest
- `checks."${name}-rust-clippy"` runs clippy
