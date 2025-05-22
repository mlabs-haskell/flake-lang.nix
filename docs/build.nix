{ flake-parts-lib, inputs, ... }:
{
  perSystem =
    { pkgs, config, ... }:

    # NOTE(jaredponn): What is going on here to generate the documentation?
    # Since flake-parts is using the module system, and NixOS also uses the
    # module system; we copy how NixOS generates their documentation:
    #  [1] The Nix function which builds the documentation returning an attribute
    #    set of a bunch of goodies:
    #    https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-options-doc/default.nix
    #  [2] The file where NixOS builds its own documentation:
    #    https://github.com/NixOS/nixpkgs/blob/master/doc/default.nix
    let
      rootSrcUrl = "https://github.com/mlabs-haskell/flake-lang.nix/blob/master";
      eval =
        # pkgs.lib.evalModules
        flake-parts-lib.evalFlakeModule { inherit inputs; } {
          imports = [
            ../flake-lang/build.nix
          ];
        };
      optionsDoc = pkgs.nixosOptionsDoc {
        inherit (eval) options;
        documentType = "none";
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
          then
            opt
            // {
              # Need to do some work s.t. we refer to the
              # actual github repo instead of the nix
              # store
              declarations = builtins.map (
                decl:
                let
                  matches = builtins.match ''${builtins.toString ./..}/(.*)'' decl;
                in
                if matches != null then
                  let
                    matched = builtins.elemAt matches 0;
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
                else
                  decl
              ) opt.declarations;
            }
          else
            opt // { visible = false; };
      };

    in
    {

      packages = {
        # Documentation outputs produced from [1]
        options-doc-json = optionsDoc.optionsJSON;
        options-doc-common-mark = optionsDoc.optionsCommonMark;

        # Documentation
        docs = pkgs.stdenv.mkDerivation {
          name = "flake-lang-docs";
          nativeBuildInputs = [ pkgs.mdbook ];

          src = ./.;

          OPTIONS_DOC_COMMON_MARK = config.packages.options-doc-common-mark;

          configurePhase = ''
            # Provide a command for linking `$OPTIONS_DOC_COMMON_MARK`
            # for use when in a developer shell.
            link-options-doc-common-mark() {
                2>&1 echo "link-options-doc-common-mark: creating a symbolic link named \`./src/api_reference.md\` pointing to \`\$OPTIONS_DOC_COMMON_MARK\`"
                ln -sf ${pkgs.lib.escapeShellArg config.packages.options-doc-common-mark} ./src/api_reference.md
            }

            link-options-doc-common-mark
          '';

          buildPhase = ''
            mdbook build --dest-dir book
          '';

          installPhase = ''
            mkdir -p "$out"
            mv book/* "$out"
          '';
        };
      };

      devShells = {
        dev-docs = config.packages.docs.overrideAttrs (
          _self: super: {
            shellHook = ''
              ${config.settings.shell.hook}
              ${super.configurePhase}
            '';
          }
        );
      };
    };
}
