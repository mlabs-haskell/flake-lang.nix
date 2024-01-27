pkgs:
{ name
, src
, # `dependencies` is of type
  # ```
  # [ nix derivation for a tarball from `npm pack` ]
  # ```
  # for the the extra dependencies (not included in the `package.json`) for
  # `node` to execute. This will _not_ install the "transitive" dependencies.
  #
  # Loosely, this will (in the order given) copy each tarball to a local
  # directory, call `npm cache` on the tarball, and finally call `npm install`.
  #
  # For example, if one wanted to include `typescript` as a dependency, then
  # one could have
  #
  # ```
  # let pkgs = import <nixpkgs> {}
  #     dependencies = [
  #           (pkgs.fetchurl {
  #             url = "https://registry.npmjs.org/typescript/-/typescript-5.2.2.tgz";
  #             sha512 = "mI4WrpHsbCIcwT9cF4FZvr80QUeKvsUsUvKDoR+X/7XHQH98xYD8YHZg7ANtz2GtZt/CBq2QJ0thkGJMHfqc1w==";
  #           })
  #    ];
  # in ...
  # ```

  npmExtraDependencies ? [ ]
, # The script to build the project i.e., `npm run ${npmBuildScript}` is
  # executed.
  npmBuildScript ? "build"
, nodejs ? pkgs.nodejs
, # `devShellHook` is the shell commands to run _before_  entering the shell
  # (see the variable `shell`)
  devShellHook ? ""
, # `devShellTools` are extra packages one may use in the dev shell
  devShellTools ? [ ]
, # `testTools` are extra derivations to append to the `buildInputs` for
  # the tests (see the variable `test`)
  testTools ? [ ]
, # Extra data to include in the project `${name}-typescript` in the directory
  # `dataDir`.
  # Type is:
  #     - List of attribute sets like:
  #         [ { name = "name"; path = "/nix/store/..."; } ]
  # Internally, this uses `pkgs.linkFarm`.
  data ? [ ]
, # Name of the directory to put `data` in.
  dataDir ? "data"
}:
pkgs.lib.makeExtensible
  (self: with self.__typescriptFlake__;
  {
    ################################
    # Overlayable attributes
    # These attributes are considered internal.
    ################################
    __typescriptFlake__ = pkgs.lib.makeExtensible (tsSelf: with tsSelf; {
      # We assume that all dependencies have their transitive closure stored in the
      # `npmExtraDependencies` attribute; so it follows that we can compute the
      # transitive closure by concatenating all dependencies together.
      # TODO(jaredponn): perhaps this should be some sort of set data structure with some sort of key...
      npmExtraDependenciesTransitiveClosure = builtins.concatMap (dep: [ dep ] ++ (dep.npmExtraDependencies or [ ])) npmExtraDependencies;

      # Folder to put the extra dependencies in
      # WARNING: we have to be a bit careful about this -- the `package.json`'s
      # expect the dependencies to be put in a specific folder.
      # NOTE(jaredponn): Why does this start with a `.`? This is because 
      #     1. It makes it a hidden file
      #     2. This no longer becomes a valid package name according to these
      #     guys:
      #     https://www.npmjs.com/package/validate-npm-package-name#naming-rules,
      #     so we can safely put all of our extra dependencies in this folder
      #     without running into troubles with node2nix later (see
      #     `extraDependenciesForNode2nix`)
      npmExtraDependenciesFolder = "./.extra-dependencies";

      # Creates something like
      #  /nix/store/....-${name}-data
      #  |-- foobar -> /nix/store/...
      #  `-- hello-test -> /nix/store/...
      #  see `pkgs.linkFarm` (a trivial builder) for details
      dataLinkFarm = pkgs.linkFarm "${name}-data" data;

      # Directory to put the `data` in
      dataFolder = dataDir;

      # Shell script to create the dataLinkFarm in the directory `dataDir`.
      dataLinkFarmCmd =
        let cmdName = "${name}-data";
        in pkgs.writeShellApplication rec {
          name = cmdName;
          runtimeInputs = [ ];
          text =
            ''
              printf "flake-lang.nix: %s: creating a symbolic link named \`%s\` pointing to \`%s\`\n" \
                  ${pkgs.lib.escapeShellArg name} \
                  ${pkgs.lib.escapeShellArg dataFolder} \
                  ${pkgs.lib.escapeShellArg dataLinkFarm}


              [[ -e ${pkgs.lib.escapeShellArg dataFolder} ]] && \
                  printf "flake-lang.nix: %s: removing existing \`%s\`\n" \
                      ${pkgs.lib.escapeShellArg name} \
                      ${pkgs.lib.escapeShellArg dataFolder}

              rm -rf ${pkgs.lib.escapeShellArg dataFolder}

              ln -sf ${pkgs.lib.escapeShellArg dataLinkFarm} \
                  ${pkgs.lib.escapeShellArg dataFolder}
            '';
        };

      # Creates a nix derivation with all the extra npm dependencies provided
      # by nix.
      # 
      # Note(jaredponn): Why are we copying everything instead of symlinking the
      # dependencies? Nix will complain (when evaluating in restricted mode on
      # HerculesCI) if we symlink the dependencies, so we copy it instead... 
      mkNpmExtraDependencies =
        pkgs.runCommand
          "${name}-npm-extra-dependencies"
          { }
          ''
            mkdir -p $out
            cd $out

            ${builtins.concatStringsSep "\n" (builtins.map (dep: ''ln -sf ${pkgs.lib.escapeShellArg dep}/tarballs/* .'') npmExtraDependenciesTransitiveClosure)}
          '';

      # Shell script to create the dependencies copied in `npmExtraDependenciesTransitiveClosure`.
      # Normally, this is run in the `configurePhase` to add the extra sources.
      mkNpmExtraDependenciesCmd =
        let cmdName = "${name}-npm-extra-dependencies";
        in pkgs.writeShellApplication rec {
          name = cmdName;
          runtimeInputs = [ ];
          text = ''
            printf "flake-lang.nix: %s: creating a symbolic link named \`%s\` pointing to \`%s\`\n" \
                ${pkgs.lib.escapeShellArg name} \
                ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder} \
                ${pkgs.lib.escapeShellArg mkNpmExtraDependencies}

              [[ -e ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder} ]] && \
                  printf "flake-lang.nix: %s: removing existing \`%s\`\n" \
                    ${pkgs.lib.escapeShellArg name} \
                    ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}

            rm -rf ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}
            ln -sf ${pkgs.lib.escapeShellArg mkNpmExtraDependencies} \
                ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}
          '';
        };


      # The result of running node2nix on the current project
      srcWithNode2nix = pkgs.stdenv.mkDerivation {
        name = "${name}-node2nix";
        inherit src;
        buildInputs = [ pkgs.node2nix nodejs mkNpmExtraDependenciesCmd dataLinkFarmCmd ];

        configurePhase =
          ''
            runHook preConfigure

            ${pkgs.lib.escapeShellArg mkNpmExtraDependenciesCmd.name}
            ${pkgs.lib.escapeShellArg dataLinkFarmCmd.name}

            runHook postConfigure
          '';

        NIX_NODE_ENV_FILE = "./node-env.nix";
        NIX_NODE_PACKAGES_FILE = "./node-packages.nix";
        NIX_COMPOSITION_FILE = "./default.nix";

        buildPhase =
          ''
            runHook preBuild

            if ! node2nix --input ./package.json --lock ./package-lock.json --development --node-env "$NIX_NODE_ENV_FILE" --output "$NIX_NODE_PACKAGES_FILE" --composition "$NIX_COMPOSITION_FILE"
            then
                1>&2 echo 'flake-lang.nix: error: `node2nix` failed.'
                1>&2 echo 'Some of the following may fix your problem:'
                1>&2 echo '   - (Re)create a `./package-lock.json` with lockfile version 2 by running:'
                1>&2 echo '          npm install --package-lock-only --lockfile-version 2          '
                exit 1
            fi

            runHook postBuild
          '';

        installPhase =
          ''
            runHook preInstall

            mkdir -p "$out"
            cp -r ./. "$out"

            runHook postInstall
          '';
      };

      # Importing the resulting nix expression produced by node2nix (IFD)
      srcWithNode2nixIfd = import "${srcWithNode2nix}/${srcWithNode2nix.NIX_COMPOSITION_FILE}" { inherit nodejs pkgs; inherit (pkgs) system; };

      # Important note:
      # Inspection of the code suggests that the node_modules are put in 
      # ```
      # $out/lib/node_modules/${srcWithNode2nixIfd.args.packageName}/node_modules
      # ```
      npmPackage = srcWithNode2nixIfd.package.override (super:
        {
          # NOTE(jaredponn): Some hacks to get around restricted mode when
          # building the derivation in CI.. Namely, it doesn't like the
          # canonical (absolute) paths that node2nix generates when accessing
          # the local dependencies, so we overrwrite those as strings so that
          # they become the relative path in `npmExtraDependenciesFolder`
          # TODO(jaredponn): we really should be more precise about how we
          # decide what is a folder dependency provided by nix instead  of just
          # checking if the src is a path
          # NOTE(jaredponn): Why are we adding the extra dependencies + the
          # data to `postConfigure` in $TMPDIR (with
          # `extraDependenciesForNode2nix`)? This is because of the way
          # node2nix works... when it installs a package, it goes to $TMPDIR,
          # THEN it installs the package.. so to ensure that all of our
          # dependencies are available, we link everything there for
          # `node2nix`.
          buildInputs = super.buildInputs ++ [ mkNpmExtraDependenciesCmd dataLinkFarmCmd ];
          dependencies = builtins.map
            (dep:
              if builtins.typeOf dep.src == "path"
              then dep // { src = pkgs.lib.path.removePrefix srcWithNode2nixIfd.args.src dep.src; }
              else dep
            )
            (super.dependencies);
          postConfigure =
            ''
              extraDependenciesForNode2nix( ) {
                local DIR

                DIR="$(pwd)"
                cd "$TMPDIR"

                ${pkgs.lib.escapeShellArg mkNpmExtraDependenciesCmd.name}
                ${pkgs.lib.escapeShellArg dataLinkFarmCmd.name}

                cd "$DIR"
              }

              extraDependenciesForNode2nix
            '';

          # NOTE(jaredponn): This note has been mostly resolved, but we leave
          # it here for historical purposes for why we used to remove the `package-lock.json`.
          #
          # Wow this is horrible. `npm install` is broken for local
          # dependencies on the filesystem. I think something like the
          # following is problematic:
          # - Suppose A is a tarball and depends on tarball B
          # - Assume that we have a "sensible" `package.json` and
          # `package-lock.json` with `./foo/A` and `./foo/B` installed
          # - If we do _not_ have `node_modules`, and try to `npm install`, `npm
          # install` will get confused and try to look in `node_modules/A/foo/B`
          # which obviously doesn't exist so it errors.
          # Apparently removing `package-lock.json` fixes this, so it can rebuild
          # it from scratch I guess?
          # This _should_ still be "reproducible" as `nix` has provided all
          # dependencies...
          # ```
          # postRebuild =
          #   ''
          #     rm package-lock.json
          #   '';
          # ```
        })
      ;

      # Build the project (runs `npm run build`)
      # This derivation is intended to have an overlay to do something useful
      # such as:
      #     - Creating a tarball of the package.

      # TODO(jaredponn): perhaps we should do something else instead of just
      # dumping everything to the nix store. Some ideas:
      #     - Do what `buildNpmPackage` i.e., copy the files declared in the
      #     `package.json` to `lib/node_modules/<package>` [which coincidentally is
      #     what `npm link` does as well]
      project = pkgs.stdenv.mkDerivation {
        name = "${name}-typescript";
        # Note we use `srcWithNode2nix` as the source, so this allows users to
        # override srcWithNode2nix's source as the "root source" of all of the
        # following derivations.
        src = srcWithNode2nix;
        buildInputs = [ nodejs mkNpmExtraDependenciesCmd dataLinkFarmCmd ];

        # `npmExtraDependencies` is used for Nix to gather all the transitive
        # dependencies so the user doesn't have to manually specify all the
        # dependencies.
        # Note(jaredponn): we confusingly just name this `npmExtraDependencies`
        # when it really is the transitive closure.
        npmExtraDependencies = npmExtraDependenciesTransitiveClosure;

        configurePhase =
          ''
            runHook preConfigure
                
            ln -sf \
                ${pkgs.lib.escapeShellArg "${npmPackage}/lib/node_modules/${srcWithNode2nixIfd.args.packageName}/node_modules"} \
                node_modules
                
            runHook postConfigure
          '';

        # Allow the the user to override the build script in the derivation
        inherit npmBuildScript;

        # Set some sane environment variables for npm
        NPM_CONFIG_OFFLINE = true;
        NPM_CONFIG_LOGLEVEL = "verbose";

        buildPhase =
          ''
            runHook preBuild

            export HOME=$(mktemp -d)

            npm run "$npmBuildScript"

            runHook postBuild
          '';

        installPhase =
          ''
            runHook preInstall

            mkdir -p "$out"
            cp -r ./. "$out"

            runHook postInstall
          '';
      };

      shell = pkgs.mkShell {
        packages = [ nodejs mkNpmExtraDependenciesCmd dataLinkFarmCmd ] ++ devShellTools;

        shellHook =
          ''
            ${pkgs.lib.escapeShellArg mkNpmExtraDependenciesCmd.name}

            ${pkgs.lib.escapeShellArg dataLinkFarmCmd.name}

            export NODE_PATH=${pkgs.lib.escapeShellArg "${npmPackage}/lib/node_modules/${srcWithNode2nixIfd.args.packageName}/node_modules"}

            [[ -e node_modules ]] && echo 'flake-lang.nix: removing existing `node_modules`'
            rm -rf node_modules

            echo 'flake-lang.nix: creating a symbolic link named `node_modules` pointing to `$NODE_PATH`'
            ln -sf "$NODE_PATH" node_modules

            ${devShellHook}
          '';

      };

      # Runs `npm install --global --prefix="$out"` for the `project`, and
      # "patches" the symlinks s.t. they reference valid data.
      npmExe = project.overrideAttrs (_self: _super:
        {
          installPhase =
            ''
              npm install \
                  --global \
                  --prefix="$out"

              # By [1], we know that the packages will be installed in
              #     - `$out/lib/node_modules`, 
              #     - the bins / man pages will be linked to `$out/bin` and
              #     `$out/share/man`
              # So, we will copy `$out/lib/node_modules`s over, and the bins /
              # mans will already point to the copied over
              # `$out/lib/node_modules`.
              #
              # References:
              #     [1] https://docs.npmjs.com/cli/v8/commands/npm-install#global

              # Copy the lib over
              find "$out/lib/node_modules" -type l -execdir \
                  sh -c '{ DEREF="$(realpath -e "$1")"; rm -rf "$1" && cp -r "$DEREF" "$1" ; }' resolve-symbolic-link '{}' \;
            '';
        }
      );

      # Creates a tarball of `project` using `npm pack` and puts it in the nix
      # store.
      npmPack = project.overrideAttrs (_self: _super:
        {
          name = "${name}-tarball";
          installPhase =
            ''
              TMPFILE=$(mktemp)

              # NOTE(jaredponn): the following commands are used to ensure that
              # the `.extra-dependencies` get copied in the resulting tarball
              # so `npm` can find it later when trying to e.g. install things.
              # TODO(jaredponn): This should blow up pretty quick in terms of
              # space complexity -- assuming we have V dependencies which form
              # a tree, since each dependency must contain all of its
              # transitive closure of dependencies, we see that this gives  a
              # bound of O(V^3) copied files.
              # A better solution would be to symlink stuff inside the tarballs
              # / find a way to tell npm that the dependencies are in the root
              # directory in `./.extra-dependencies/*`
              mv -f ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder} "$TMPFILE"
              rm -rf .gitignore # otherwise, `npm` will ignore the `.extra-dependencies`
              cp -Lr "$TMPFILE" ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}

              mkdir -p "$out/tarballs"
              npm pack --pack-destination "$out/tarballs"
            '';
        });


      # Run tests with `npm test`.
      test = project.overrideAttrs (_self: super:
        {
          # Append the test command at the end.
          postBuild =
            ''
              npm test
            '';
          installPhase =
            ''
              touch "$out"
            '';

          buildInputs = super.buildInputs ++ testTools;
        });
    });

    ################################
    # Output derivations to use in your flake.
    #################################
    devShells = {
      "${name}-typescript" = shell;
    };

    packages = {
      "${name}-typescript" = project;
      "${name}-typescript-exe" = npmExe;
      "${name}-typescript-tgz" = npmPack;
      "${name}-typescript-node2nix" = srcWithNode2nix;
    };

    checks = {
      "${name}-typescript-test" = test;
    };
  }
  )
