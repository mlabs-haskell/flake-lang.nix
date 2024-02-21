inputCrane: pkgs:

{ src
, crane ? null
, crateName
, version ? "0.1.0"
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
}:
let

  rustWithTools = pkgs.rust-bin.stable.${rustVersion}.default.override {
    extensions = [ "rustfmt" "rust-analyzer" "clippy" "rust-src" ];
  };
  craneLib =
    let
      crane' =
        if crane == null then
          inputCrane
        else
          pkgs.lib.showWarnings [ ''rustFlake: You're setting the `crane` argument which is deprecated and will be removed in the next major revision'' ] crane;

    in
    crane'.lib.${pkgs.system}.overrideToolchain rustWithTools;

  cleanSrc = craneLib.cleanCargoSource (craneLib.path src);

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

  commonArgs = {
    inherit nativeBuildInputs buildInputs;
    src = buildEnv;
    pname = crateName;
    strictDeps = true;
  };
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
    buildInputs = buildInputs ++ nativeBuildInputs;
    packages = devShellTools ++ testTools;
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
      doInstallCargoArtifacts = true;
    });

    "${crateName}-rust-src" = vendoredSrc;

    "${crateName}-rust-build-env" = buildEnv;
  };

  checks = {
    "${crateName}-rust-test" = craneLib.cargoNextest (commonArgs // {
      inherit cargoArtifacts cargoNextestExtraArgs;
      nativeBuildInputs = testTools ++ nativeBuildInputs;
    });

    "${crateName}-rust-clippy" = craneLib.cargoClippy (commonArgs // {
      inherit cargoArtifacts;
    });
  };
}
