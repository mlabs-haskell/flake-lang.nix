inputCrane: pkgs:

{ src
, extraSourceFilters ? [ ]
, crane ? null
, crateName
, version ? "v0"
, rustProfile ? "stable"
, rustVersion ? "latest"
, nativeBuildInputs ? [ ]
, buildInputs ? [ ]
, extraSources ? [ ]
, extraSourcesDir ? ".extras"
, data ? [ ]
, dataDir ? "data"
, devShellHook ? ""
, devShellTools ? [ ]
, testTools ? [ ]
, cargoNextestExtraArgs ? ""
, doInstallCargoArtifacts ? false
, target ? pkgs.stdenv.hostPlatform.config
, extraRustcFlags ? null
, extraCargoArgs ? null
, extraEnvVars ? null
}:

let
  inherit (pkgs.lib) optionalAttrs;

  rustWithTools = pkgs.rust-bin.${rustProfile}.${rustVersion}.default.override
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
          pkgs.lib.showWarnings [ ''rustFlake: You're setting the `crane` argument which is deprecated and will be removed in the next major revision'' ] crane;

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

  packages = {
    "${crateName}-rust" = craneLib.buildPackage (commonArgs // {
      inherit cargoArtifacts;
      doCheck = false;
      inherit doInstallCargoArtifacts;
    });

    "${crateName}-rust-src" = vendoredSrc;

    "${crateName}-rust-build-env" = buildEnv;
  };

  checks = {
    "${crateName}-rust-test" = craneLib.cargoNextest (commonArgs // {
      inherit cargoArtifacts cargoNextestExtraArgs;
      nativeBuildInputs = commonArgs.nativeBuildInputs ++ testTools;
    });

    "${crateName}-rust-clippy" = craneLib.cargoClippy (commonArgs // {
      inherit cargoArtifacts;
    });
  };
}
