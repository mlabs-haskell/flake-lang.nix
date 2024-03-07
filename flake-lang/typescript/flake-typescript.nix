pkgs:
{ name
, src
, # `dependencies` is of type
  # ```
  # [ file or folder ]
  # ```
  # This most likely should be the `*-lib` output of another TypeScript flake
  # produced by this Nix function.
  #
  # In general, the list may have elements which are either:
  #     - folder with a `package.json` file (a npm package)
  #     - a folder to an npm package at `./tarballs/`
  #     - a folder to an npm package at `./lib/node_modules/`
  #     - a tarball containing an npm package
  # 
  # This argument `dependencies` is the extra dependencies provided by nix for
  # npm. This will _not_ install the "transitive" dependencies.
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
      mkNpmExtraDependencies =
        pkgs.runCommand
          "${name}-npm-extra-dependencies"
          { }
          ''
            mkdir -p $out
            cd $out

            ${builtins.concatStringsSep "\n" 
                (builtins.map 
                    (dep: 
                        ''
                        if test -d ${pkgs.lib.escapeShellArg dep}
                        then
                            if test -f ${pkgs.lib.escapeShellArg dep}/package.json
                            then
                                ln -sf ${pkgs.lib.escapeShellArg dep} .
                            else
                                test -d ${pkgs.lib.escapeShellArg dep}/tarballs \
                                    && find ${pkgs.lib.escapeShellArg dep}/tarballs \
                                        -mindepth 1 \
                                        -maxdepth 1 \
                                        -exec ln -sf '{}' . \;

                                test -d ${pkgs.lib.escapeShellArg dep}/lib/node_modules \
                                    && find ${pkgs.lib.escapeShellArg dep}/lib/node_modules \
                                        -mindepth 1 \
                                        -maxdepth 1 \
                                        -exec ln -sf '{}' . \;
                            fi
                        else
                            ln -sf ${pkgs.lib.escapeShellArg dep} .
                        fi
                        '') 
                        npmExtraDependenciesTransitiveClosure)
            }
          '';

      # Shell script to create the dependencies copied in `npmExtraDependenciesTransitiveClosure`.
      # Normally, this is run in the `configurePhase` to add the extra sources.
      mkNpmExtraDependenciesCmd =
        let cmdName = "${name}-npm-extra-dependencies";
        in pkgs.writeShellApplication rec {
          name = cmdName;
          runtimeInputs = [ ];
          # NOTE(jaredponn): Why are we copying everything when symlinking
          # might suffice?
          # ~~~~~~~~~~~~~~~~~~~
          # When we run `npm install some/path/which/contains/a/symlink` it'll
          # rewrite this to the relative path of the dereferenced symlink e.g.
          # running `npm install mypackage` for
          # ```
          # mypackage --> /nix/store/../somepkg
          # ```
          # will make `npm` write something like
          # ```
          # file:../../../../../nix/store/../somepkg
          # ```
          # in the `package.json` and `package-lock.json`
          # Clearly, this is unusable.
          text = ''
            1>&2 printf "flake-lang.nix: %s: creating a copy of \`%s\` to \`%s\`\n" \
                ${pkgs.lib.escapeShellArg name} \
                ${pkgs.lib.escapeShellArg mkNpmExtraDependencies} \
                ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}

            [[ -e ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder} ]] && \
                  1>&2 printf "flake-lang.nix: %s: removing existing \`%s\`\n" \
                    ${pkgs.lib.escapeShellArg name} \
                    ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}

            rm -rf ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}

            mkdir -p ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}
            cp -f -Lr --no-preserve=all ${pkgs.lib.escapeShellArg mkNpmExtraDependencies}/. \
                ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}

            # NOTE(jaredponn): perhaps in the future it will be helpful to
            # output this
            # ```
            # echo ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder}
            # ```
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
              dep
              # if builtins.typeOf dep.src == "path"
              # # then dep // { src = pkgs.lib.path.removePrefix srcWithNode2nixIfd.args.src dep.src; }
              # then dep // { src = pkgs.lib.path.removePrefix srcWithNode2nixIfd.args.src dep.src; }
              # else dep
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
          # NOTE(jaredponn): Yet another troubling note.. inspection of the
          # code generated by `node2nix` makes it call `npm` install (unless
          # otherwise specified) just after their `rebuildPhase`.
          # Putting this here seems to "tell `npm` the complete picture" of the
          # packages it can install, so it won't duplicate the local
          # dependencies in the `node_modules` provided by nix multiple times.
          # For example, if we have
          #     - A depends on B
          #     - B depends on C
          # Then, without this, `npm` would create a dependency graph something
          # like:
          # ```
          # A-B-C
          #  `C
          # ```
          # instead of the more desirable
          # ```
          # A-B
          #  `C
          # ```
          # Unfortunately, there is no trace of this in the documentation
          # anywhere, and we only have some experimental evidence for this.
          # Alternatively, we could just set the `dontNpmInstall` flag in
          # node2nix, but I'm not sure of the consequences of that...
          postRebuild =
            ''
              npm --offline --no-bin-links --ignore-scripts --package-lock-only install 
            '';
        })
      ;

      # Build the project (runs `npm run build`), then runs `npm install` where
      # the install outputs are copied to "$out"
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

            runHook postInstall
          '';
      };

      # Unzips the files from `npmPack` and puts them in
      # `$out/lib/node_modules/<package-name>/`
      # TODO(jaredponn): pry open the npm source code and find a way to list
      # the files s.t. we can just copy them ourselves.
      npmLib = pkgs.stdenv.mkDerivation {
        name = "${name}-typescript-lib";
        dontUnpack = true;
        installPhase = ''
          mkdir -p "$out/lib/node_modules/${srcWithNode2nixIfd.args.packageName}"
          find "${npmPack}/tarballs" -type f -mindepth 1 -maxdepth 1 -exec tar -xzvf '{}' \;
          find ./package -mindepth 1 -maxdepth 1 -exec mv '{}' "$out/lib/node_modules/${srcWithNode2nixIfd.args.packageName}" \;
        '';
      };

      # Alias for `project`
      npmExe = project;

      shell = pkgs.mkShell {
        packages = [ nodejs mkNpmExtraDependenciesCmd dataLinkFarmCmd ] ++ testTools ++ devShellTools;

        shellHook =
          ''
            # Check if the current directory's `package.json`'s is the same as
            # the `package.json` of the project.
            # This is a coarse test to verify that we are entering the shell in
            # the same directory the project is in.
            if ! { test -f ./package.json && cmp -s ./package.json "${srcWithNode2nix}/package.json" ; }
            then
                1>&2 echo 'flake-lang.nix: warning: entering the development shell in a different directory from the actual directory of the project.'
                1>&2 echo '    When entering the development shell, flake-lang.nix provides the folder `./node_modules` (among others), so it is important to enter the development shell in the same directory the project is in.'
            fi

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

      # Creates a tarball of `project` using `npm pack` and puts it in the nix
      # store.
      npmPack = project.overrideAttrs (_self: _super:
        {
          name = "${name}-tarball";
          installPhase =
            ''
              # NOTE(jaredponn): the following commands are used to ensure that
              # the `.extra-dependencies` get copied in the resulting tarball
              # so `npm` can find it later when trying to e.g. install things.
              # TODO(jaredponn): This should blow up pretty quick in terms of
              # space complexity -- assuming we have V dependencies which form
              # a tree, since each dependency must contain all of its
              # transitive closure of dependencies, we see that this gives a
              # bound of O(V^3) copied files.
              # A better solution would be to symlink stuff inside the tarballs
              # / find a way to tell npm that the dependencies are in the root
              # directory in `./.extra-dependencies/*`
              if [ -e ${pkgs.lib.escapeShellArg npmExtraDependenciesFolder} ]
              then
                  rm -rf .gitignore # otherwise, `npm` will ignore the `.extra-dependencies`
              fi

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
      "${name}-typescript-lib" = npmLib;
      "${name}-typescript-tgz" = npmPack;
      "${name}-typescript-node2nix" = srcWithNode2nix;
    };

    checks = {
      "${name}-typescript-test" = test;
    };
  }
  )
