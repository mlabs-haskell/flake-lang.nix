{ flake-parts-lib, inputs, ... }: {
  perSystem = { pkgs, config, ... }:

    # Note(jaredponn): What is going on here to generate the documentation?
    # Since flake-parts is using the module system and nixos also uses the
    # module system, we copy how they generate documentation:
    #  - The nix function which builds the documentation 
    #    https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-options-doc/default.nix
    #  - The file where they actually build the documentation
    #    https://github.com/NixOS/nixpkgs/blob/master/doc/default.nix
    let
      # TODO(jaredponn): make this a module option or something so someone
      # can set this somewhere else...
      rootSrcUrl = "https://github.com/mlabs-haskell/flake-lang.nix/blob/master";
      eval =
        # pkgs.lib.evalModules
        flake-parts-lib.evalFlakeModule
          { inherit inputs; }
          {
            imports =
              [
                ../flake-lang/build.nix
              ];
          };
      optionsDoc = pkgs.nixosOptionsDoc {
        inherit (eval) options;
        documentType = "none";
        revision = "none";
        # We only want to include the options provided by us (there's a
        # bunch of extra garbage provided by flake-parts).
        # So, we set the attribute `.visible` to `false` for all options
        # which are not defined in `*.lib.*` (where we recall `*.lib.* is
        # our stuff)
        transformOptions =
          opt:
          if
          # Either `lib` is the first thing, or it's in some nested attribute
            builtins.match ''^(.*\.)?lib(\..+)?$'' opt.name != null
          then opt
            //
            {
              # Need to do some work s.t. we refer to the
              # actual github repo instead of the nix
              # store
              declarations =
                builtins.map
                  (decl:
                    let matches = builtins.match ''${builtins.toString ./..}/(.*)'' decl;
                    in if matches != null
                    then
                      let matched = builtins.elemAt matches 0;
                      in
                      {
                        # TODO(jaredponn):
                        # What about
                        # weird URLS?
                        # shouldn't we
                        # escape the
                        # URL in a
                        # reasonable
                        # sense?
                        url = "${rootSrcUrl}/${matched}";
                        name = matched;
                      }
                    else decl
                  )
                  opt.declarations;
            }
          else opt // { visible = false; };
      };

    in
    {

      packages = {
        # Useful for debugging.
        docs-raw-json = optionsDoc.optionsJSON;
        docs-raw-common-mark = optionsDoc.optionsCommonMark;

        # Documentation
        docs = pkgs.runCommand
          "flake-lang-docs"
          { nativeBuildInputs = [ pkgs.pandoc ]; }
          ''
            pandoc ${pkgs.lib.escapeShellArg config.packages.docs-raw-common-mark} \
                --metadata title="flake-lang.nix" \
                --standalone \
                --output index.html

            mkdir -p "$out"
            mv index.html "$out"
          '';
      };
    };
}
