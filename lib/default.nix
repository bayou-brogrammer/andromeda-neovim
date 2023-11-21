{lib, ...}: rec {
  # and this is the code from neovimUtils that it calls
  legacyWrapper = pkgs: neovim: {
    # except I also passed this through
    wrapRc ? true,
    extraName ? "",
    configure ? {},
    viAlias ? false,
    # With
    withRuby ? true,
    vimAlias ? false,
    withPython3 ? true,
    withNodeJs ? false,
    # Extras
    extraLuaPackages ? [],
    extraPythonPackages ? [],
    extraPython3Packages ? [],
    extraMakeWrapperArgs ? "",
  }: let
    genPlugin = packageName: {start ? []}: start;

    plugins =
      pkgs.lib.flatten (pkgs.lib.mapAttrsToList
        genPlugin (configure.packages or {}));

    res = pkgs.neovimUtils.makeNeovimConfig {
      inherit extraLuaPackages extraPython3Packages extraPythonPackages;
      inherit withNodeJs withRuby withPython3;
      inherit extraName viAlias vimAlias;
      inherit plugins;

      customRC = configure.customRC or "";
    };
  in
    pkgs.wrapNeovimUnstable neovim (res
      // {
        # and changed this
        inherit wrapRc;
        wrapperArgs =
          lib.escapeShellArgs res.wrapperArgs
          + " "
          + extraMakeWrapperArgs;
      });

  # Source: https://github.com/NixOS/nixpkgs/blob/41de143fda10e33be0f47eab2bfe08a50f234267/pkgs/applications/editors/neovim/utils.nix#L24C9-L24C9
  # this is the code for wrapNeovim from nixpkgs
  wrapNeovim = pkgs: neovim-unwrapped:
    lib.makeOverridable
    (legacyWrapper pkgs neovim-unwrapped);

  NeovimBuilder = {
    self,
    pkgs,
    sources,
    # Settings
    settings ? {},
    # Wrappers
    extraWrapperArgs ? {},
    lspsAndRuntimeDeps ? {},
    environmentVariables ? {},
    propagatedBuildInputs ? [],
    # Extra packages
    extraLuaPackages ? {},
    extraPythonPackages ? {},
    extraPython3Packages ? {},
  }: let
    config =
      {
        RCName = "";
        wrapRc = true;
        extraName = "";
        viAlias = false;
        withRuby = true;
        vimAlias = false;
        withNodeJs = false;
        withPython3 = true;
      }
      // settings;

    buildPlugin = name: source:
      pkgs.vimUtils.buildVimPlugin {
        src = source;
        name = "${name}-${source.rev}";
        namePrefix = ""; # Clear name prefix
      };

    generatedPluginSources = with lib;
      mapAttrs'
      (n: v: nameValuePair (builtins.replaceStrings ["plugin-"] [""] n) v)
      (filterAttrs (n: _: hasPrefix "plugin-" n) sources);

    generatedPlugins = with lib;
      mapAttrs buildPlugin generatedPluginSources;

    plugins =
      generatedPlugins
      // {
        # Add plugins you want synced with nixpkgs here, or override
        # existing ones from the generated plugin set.
        inherit (pkgs.vimPlugins) nvim-treesitter nvim-treesitter-textobjects nvim-treesitter-refactor;
      };

    pluginDir = with lib;
      pkgs.linkFarm "nvim-plugins" (mapAttrsToList (n: v: {
          name = n;
          path = v;
        })
        plugins);
    # parserDir = lib.milkyvim.generateTreesitterGrammar pkgs sources;

    # package the entire flake as plugin
    LuaConfig = pkgs.stdenv.mkDerivation {
      name = config.RCName;
      builder = pkgs.writeText "builder.sh" ''
        source $stdenv/setup
        mkdir -p $out
        cp -r ${self}/lua $out

        mkdir -p $out/plugins
        cp -r ${pluginDir}/* $out/plugins
      '';
    };

    # package the entire flake as plugin
    # Plugins = pkgs.stdenv.mkDerivation {
    #   name = config.RCName + "-plugins";
    #   builder = pkgs.writeText "builder.sh" ''
    #     source $stdenv/setup
    #     mkdir -p $out/plugins
    #     cp -r ${pluginDir}/* $out/plugins
    #   '';
    # };

    # Parsers = pkgs.stdenv.mkDerivation {
    #   name = config.RCName + "-parsers";
    #   builder = pkgs.writeText "builder.sh" ''
    #     source $stdenv/setup
    #     mkdir -p $out/parsers
    #     cp -r ${parserDir}/* $out/parsers
    #   '';
    # };

    wrapRc =
      if config.RCName != ""
      then config.wrapRc
      else false;

    # and create our customRC to call it
    customRC =
      if wrapRc
      then ''lua require('${config.RCName}')''
      else "";

    extraPlugins =
      if wrapRc
      then [LuaConfig]
      # ++ lib.optional (treesitterParsers != {}) Parsers
      else [];

    # add any dependencies/lsps/whatever we need available at runtime
    wrapRuntimeDeps =
      builtins.map
      (value: ''--prefix PATH : "${lib.makeBinPath [value]}"'');

    wrappedRuntimeDeps =
      wrapRuntimeDeps lspsAndRuntimeDeps;
    wrappedEnvironmentVars =
      lib.mapAttrsToList (name: value: ''--set ${name} "${value}"'')
      (environmentVariables // {PLUGIN_PATH = "${LuaConfig}";});

    # cat our args
    extraMakeWrapperArgs = builtins.concatStringsSep " " (
      wrappedRuntimeDeps
      ++ wrappedEnvironmentVars
      ++ extraWrapperArgs
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    );

    # I didnt add stdenv.cc.cc.lib, so I would suggest not removing it.
    # It has cmake in it I think among other things?
    buildInputs =
      [pkgs.stdenv.cc.cc.lib]
      ++ propagatedBuildInputs;

    # add our propagated build dependencies
    myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (_: {
      propagatedBuildInputs = buildInputs;
    });

    # extraPythonPackages and the like require FUNCTIONS that return lists.
    # so we make a function that returns a function that returns lists.
    # this is used for the fields in the wrapper where the default value is (_: [])
    combineCatsOfFuncs = sect: (x: let
      appliedfunctions = builtins.map (value: value x) sect;
      uniquifiedList = lib.unique (builtins.concatLists appliedfunctions);
    in
      uniquifiedList);

    start =
      extraPlugins
      ++ [pkgs.vimPlugins.lazy-nvim];
  in
    # add our lsps and plugins and our config, and wrap it all up!
    wrapNeovim pkgs myNeovimUnwrapped {
      inherit wrapRc extraMakeWrapperArgs;
      inherit (config) vimAlias viAlias withRuby extraName withNodeJs withPython3;

      configure = {
        inherit customRC;
        packages.myVimPackage = {
          inherit start;
        };
      };

      extraLuaPackages = combineCatsOfFuncs extraLuaPackages;
      extraPythonPackages = combineCatsOfFuncs extraPythonPackages;
      extraPython3Packages = combineCatsOfFuncs extraPython3Packages;
    };
}
