<!-- This file is used in `../build.nix`'s `description` for TS -->

<!-- markdownlint-disable MD041 -->
Creates a flake for a TypeScript project.

Returns an attribute set of the form

```nix
{
  devShells."${name}-typescript" = derivation { ... };
  packages."${name}-typescript" = derivation { ... };
  packages."${name}-typescript-exe" = derivation { ... };
  packages."${name}-typescript-tgz" = derivation { ... };
  packages."${name}-typescript-node2nix" = derivation { ... };
  checks."${name}-typescript-test" = derivation { ... };
}
```

where

- `packages."${name}-typescript"` contains the project with a
  `node_modules/` provided by Nix (in the `configurePhase`), and
   its `buildPhase` runs `npm run "$npmBuildScript"` (where `npmBuildScript` is
   `build` by default).
   Indeed, one can overlay the entire derivation (which contains
   all its dependencies) to postprocess their project as they
   see fit. For example, one may want to generate documentation
   instead of building the project, by running:

   ```nix
   packages."${name}-typescript".overrideAttrs (_self: _super: {
     npmBuildScript = "docs";
     installPhase = 
        ''
            mv ./docs "$out"
        '';
    });
    ```

    where we assume that the `package.json` contains
    `scripts.docs = <some-script>` which produces documentation
    in the `./docs` folder.

- `devShells."${name}-typescript-test"` provides a developer shell with
  the environment variable `NODE_PATH` as the path to the
  `node_modules/` produced by Nix, and the command
  `${name}-npm-extra-dependencies` which copies the transitive
  closure of `npmExtraDependencies` to the folder `./extra-dependencies`.

  Moreover, the `shellHook` will:
      - create a symbolic link named `node_modules` pointing to
        `$NODE_PATH`; and
      - executes `${name}-npm-extra-dependencies`.

- `packages."${name}-typescript-exe"` is `packages."${name}-typescript"` except
  runs `npm install --global --prefix="$out"` for the `installPhase` and
  copies some of the symbolic links so that the output makes sense.

- `packages."${name}-typescript-tgz"` is `packages."${name}-typescript"` except
  runs `npm pack` after the `buildPhase` to create a tarball of the project in
  the directory `$out/tarballs/`.

- `packages."${name}-typescript-test"` is `packages."${name}-typescript"`
  except it runs `npm test` after the `buildPhase` succeeding only if `npm
  test` succeeds.
