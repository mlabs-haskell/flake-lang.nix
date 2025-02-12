inputCrane: pkgs:

{
  # Source folder (unfiltered)
  src
, # Extra filters to add non-rust related files to the derivation
  extraSourceFilters ? [ ]
, crane ? null # deprecated
, # Name of the project
  crateName
, # Major version of the project
  version ? "v0"
, # Rust channel (stable, nightly, etc.)
  rustChannel ? "stable"
, rustProfile ? null # deprecated
, # Rust version
  rustVersion ? "latest"
, # Additional native build inputs
  nativeBuildInputs ? [ ]
, # Additional build inputs
  buildInputs ? [ ]
, # Extra sources, allowing to use other rustFlake components to be used as dependencies
  extraSources ? [ ]
, # Folder to store extra source libraries
  extraSourcesDir ? ".extras"
, # Data dependencies
  data ? [ ]
, # Folder to store the data dependencies
  dataDir ? "data"
, # Shell script executed after entering the dev shell
  devShellHook ? ""
, # Packages made available in the dev shell
  devShellTools ? [ ]
, # Packages made available in checks and the dev shell
  testTools ? [ ]
, # Extra cargo nextest arguments
  cargoNextestExtraArgs ? ""
, # Controls whether cargo's target directory should be copied as an output
  doInstallCargoArtifacts ? false
, # Rust compilation target
  target ? pkgs.stdenv.hostPlatform.config
, # Extra rustc flags
  extraRustcFlags ? null
, # Extra cargo arguments
  extraCargoArgs ? null
, # Extra environment variables
  extraEnvVars ? null
  # Generate Rustdoc
, generateDocs ? true
  # Build testsuite as standalone executables
, exportTests ? false
  # Run testsuite using cargo-nextest
, runTests ? true
  # Run clippy linter
, runClippy ? true
}:

let
  inherit (pkgs.lib) optionalAttrs;

  rustWithTools =
    let
      rustChannel' =
        if rustProfile == null
        then rustChannel
        else
          pkgs.lib.showWarnings
            [ ''rustFlake: The `rustProfile` argument is deprecated, please use `rustChannel` instead'' ]
            rustProfile;
    in
    pkgs.rust-bin.${rustChannel'}.${rustVersion}.default.override
      {
        extensions = [ "rustfmt" "rust-analyzer" "clippy" "rust-src" ];
        targets = [ target ];
      };

  craneLib =
    let
      crane' =
        if crane == null then
          inputCrane
        else
          pkgs.lib.showWarnings
            [ ''rustFlake: You're setting the `crane` argument which is deprecated and will be removed in the next major revision'' ]
            crane;

    in
    (crane'.mkLib pkgs).overrideToolchain rustWithTools;

  cleanSrc =
    let
      filter = path: type:
        pkgs.lib.foldr
          (filterFn: result: result || filterFn path type)
          (craneLib.filterCargoSources path type)
          extraSourceFilters;

    in
    pkgs.lib.cleanSourceWith {
      inherit src filter;
      name = "source";
    };

  # Library source code with extra dependencies copied
  buildEnv =
    pkgs.stdenv.mkDerivation
      {
        src = cleanSrc;
        name = "${crateName}-build-env";
        unpackPhase = ''
          mkdir $out
          cp -r $src/* $out
          cd $out
          ${copyExtraSources}
          ${copyData}
        '';
      };

  # Library source code, intended to be used in extraSources
  # Dependencies of this crate are not copied, to the extra sources directory
  # but they are referenced from the parent directory (parent crate's extra sources).
  vendoredSrc =
    pkgs.stdenv.mkDerivation
      {
        src = cleanSrc;
        name = "${crateName}-${version}";
        unpackPhase = ''
          mkdir $out
          cp -r $src/* $out
          cd $out
          sed -Ei 's/${pkgs.lib.escapeRegex extraSourcesDir}/../g' Cargo.toml
        '';
      };


  defNativeBuildInputs =
    (pkgs.lib.optionals pkgs.stdenv.isLinux [
      pkgs.pkg-config
    ]) ++
    (pkgs.lib.optionals pkgs.stdenv.isDarwin
      [
        pkgs.gcc
        pkgs.darwin.apple_sdk.frameworks.Security
        pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
      ]);
  defBuildInputs = [
    pkgs.openssl.dev
  ];

  commonArgs = {
    nativeBuildInputs = defNativeBuildInputs ++ nativeBuildInputs;
    buildInputs = defBuildInputs ++ buildInputs;
    src = buildEnv;
    pname = crateName;
    strictDeps = true;
  } // optionalAttrs (target != null) {
    CARGO_BUILD_TARGET = target;
  } // optionalAttrs (extraRustcFlags != null) {
    CARGO_BUILD_RUSTFLAGS = extraRustcFlags;
  } // optionalAttrs (extraCargoArgs != null) {
    cargoExtraArgs = extraCargoArgs;
  } // optionalAttrs (extraEnvVars != null) extraEnvVars;

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  # Extra sources
  extra-sources = pkgs.linkFarm "extra-sources" (builtins.map (drv: { name = drv.name; path = drv; }) extraSources);

  hasExtraSources = builtins.length extraSources > 0;
  linkExtraSources = pkgs.lib.optionalString hasExtraSources ''
    echo "Linking extra sources"
    if [ -e ./${extraSourcesDir} ]; then rm ./${extraSourcesDir}; fi
    ln -s ${extra-sources} ./${extraSourcesDir}
  '';
  copyExtraSources = pkgs.lib.optionalString hasExtraSources ''
    echo "Copying extra sources"
    cp -Lr ${extra-sources} ./${extraSourcesDir}
  '';

  # Data
  data-drv = pkgs.linkFarm "data" data;
  hasData = builtins.length data > 0;
  linkData = pkgs.lib.optionalString hasData ''
    echo "Linking data"
    if [ -e ./${dataDir} ]; then rm ./${dataDir}; fi
    ln -s ${data-drv} ./${dataDir}
  '';
  copyData = pkgs.lib.optionalString hasData ''
    echo "Copying data"
    cp -Lr ${data-drv} ./${dataDir}
  '';
in
{
  devShells."dev-${crateName}-rust" = craneLib.devShell {
    buildInputs = commonArgs.buildInputs ++ commonArgs.nativeBuildInputs;
    packages = devShellTools ++ [ pkgs.cargo-nextest ] ++ testTools;
    shellHook = ''
      ${linkExtraSources}
      ${linkData}
      ${devShellHook}
    '';
  };

  packages = (optionalAttrs generateDocs {
    "${crateName}-rust-doc" = craneLib.cargoDoc (commonArgs // {
      inherit cargoArtifacts;
      doCheck = false;
      inherit doInstallCargoArtifacts;
    });

  }) // (optionalAttrs exportTests {
    "${crateName}-rust-test" = craneLib.buildPackage (commonArgs // {
      inherit cargoArtifacts;
      doCheck = false;
      buildInputs = commonArgs.buildInputs ++ [ pkgs.bash ];
      cargoExtraArgs = cargoNextestExtraArgs + " --tests";
      nativeBuildInputs = commonArgs.nativeBuildInputs ++ testTools ++ [ pkgs.jq ];
      installPhaseCommand = ''
        files=$(cat $cargoBuildLog | jq -r 'select(.target.kind | . != null and contains(["test"])).executable')
        mkdir -p $out/bin

        echo $files | xargs -r mv -t $out/bin

        echo "#!${pkgs.bash}/bin/bash" > $out/bin/run_tests.sh
        echo "set -e" >> $out/bin/run_tests.sh

        for file in $files; do
          echo $out/bin/$(basename $file) >> $out/bin/run_tests.sh
        done
        chmod a+x $out/bin/run_tests.sh
      '';
    });
  }) // {
    "${crateName}-rust" = craneLib.buildPackage (commonArgs // {
      inherit cargoArtifacts;
      doCheck = false;
      inherit doInstallCargoArtifacts;
    });


    "${crateName}-rust-src" = vendoredSrc;

    "${crateName}-rust-build-env" = buildEnv;

  };

  checks =
    (optionalAttrs runTests {
      "${crateName}-rust-test" = craneLib.cargoNextest (commonArgs // {
        inherit cargoArtifacts cargoNextestExtraArgs;
        nativeBuildInputs = commonArgs.nativeBuildInputs ++ testTools;
      });
    }) // (optionalAttrs runClippy {

      "${crateName}-rust-clippy" = craneLib.cargoClippy (commonArgs // {
        inherit cargoArtifacts;
      });
    });
}
