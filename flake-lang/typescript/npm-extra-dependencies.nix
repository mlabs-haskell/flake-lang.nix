{ runCommand
, lib
, writeShellApplication
, ...
}:
{ name
, npmExtraDependencies
, ...
}:
lib.makeExtensible
  (self:
  {
    # Note(jaredponn): Why are we copying everything instead of symlinking the
    # dependencies? Nix will complain (when evaluating in restricted mode on
    # HerculesCI) if we symlink the dependencies, so we copy it instead... 
    npmExtraDependencies = runCommand
      "${name}-npm-extra-dependencies"
      { }
      ''
        mkdir -p $out
        cd $out
        ${builtins.concatStringsSep "\n" (builtins.map (dep: ''cp -r "${dep}/tarballs/"* .'') npmExtraDependencies)}
      '';

    npmExtraDependenciesFolder = "./extra-dependencies";

    npmLinkExtraDependencies = writeShellApplication
      {
        name = "${name}-npm-link-extra-dependencies";
        runtimeInputs = [ ];
        text = ''
          echo "Linking dependencies \`${self.npmExtraDependencies}\` to \`${self.npmExtraDependenciesFolder}\`"
          rm -rf ${self.npmExtraDependenciesFolder}
          cp -r "${self.npmExtraDependencies}" "${self.npmExtraDependenciesFolder}"
        '';
      };
  }
  )
