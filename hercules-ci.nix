{ inputs, ... }: {
  imports = [
    inputs.hci-effects.flakeModule
  ];

  hercules-ci.flake-update = {
    enable = true;
    updateBranch = "updated-flake-lock";
    # Next two parameters should always be set explicitly
    createPullRequest = true;
    autoMergeMethod = null;
    when = {
      # Perform update by Sundays at 12:45
      minute = 45;
      hour = 12;
      dayOfWeek = "Sun";
    };
  };
  # TODO(jaredponn): figure out how this is going to be documented..
  # Some remarks:
  #     - Using `flake.parts-website` is a bit painful because
  #         1. It only documents inputs to the flake (unless you do some magic
  #         to [somehow] evaluate the module separately?)
  #         2. By default it includes some extra modules that aren't really
  #         necessary..
  #         3. Also the documentation barely exists...
  # hercules-ci.github-pages.branch = "main";
  # perSystem = { config, ... }: {
  #   hercules-ci.github-pages.settings.contents = config.packages.docs;
  # };

  herculesCI.ciSystems = [ "x86_64-linux" ];
}
