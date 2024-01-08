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

    npmExtraDependencies = runCommand
      "${name}-npm-extra-dependencies"
      { }
      ''
        # Symlinks all the provided dependencies to $out
        mkdir -p $out
        cd $out
        ${builtins.concatStringsSep "\n" (builtins.map (dep: ''ln -sf "${dep}/tarballs/"* .'') npmExtraDependencies) }
      '';

    npmExtraDependenciesFolder = "./extra-packages";

    npmLinkExtraDependencies = writeShellApplication
      {
        name = "${name}-npm-link-extra-dependencies";
        runtimeInputs = [ ];
        text = ''
          echo 'Linking dependencies `${self.npmExtraDependencies}` to `${self.npmExtraDependenciesFolder}`'
          rm -rf ${self.npmExtraDependenciesFolder}
          ln -sf "${self.npmExtraDependencies}" ${self.npmExtraDependenciesFolder}
        '';
      }
      }
      )
