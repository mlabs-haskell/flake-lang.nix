{ flake-parts-lib, lib, ... }: {
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.settings.defaultShellHook = lib.mkOption {
      type = lib.types.separatedString "\n";
      default = "";
    };
  };

  config.perSystem = { config, ... }: {
    settings.defaultShellHook = ''
      export LC_CTYPE=C.UTF-8
      export LC_ALL=C.UTF-8
      export LANG=C.UTF-8
      ${config.pre-commit.installationScript}
    '';
  };
}
