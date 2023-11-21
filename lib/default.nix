{lib, ...}:
with lib.milkyvim; {
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

    pluginDir = generateNeovimPlugins pkgs sources;
    parserDir = generateTreesitterGrammar pkgs sources;

    # package the entire flake as plugin
    LuaConfig = pkgs.stdenv.mkDerivation {
      name = config.RCName;
      builder = pkgs.writeText "builder.sh" ''
        source $stdenv/setup
        mkdir -p $out
        cp -r ${self}/lua $out

        mkdir -p $out/plugins
        cp -r ${pluginDir}/* $out/plugins

        mkdir -p $out/parsers
        cp -r ${parserDir}/* $out/parsers
      '';
    };

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
  in
    # add our lsps and plugins and our config, and wrap it all up!
    wrapNeovim pkgs myNeovimUnwrapped {
      inherit wrapRc extraMakeWrapperArgs;
      inherit (config) vimAlias viAlias withRuby extraName withNodeJs withPython3;

      configure = {
        inherit customRC;
        plugins = extraPlugins ++ [pkgs.vimPlugins.lazy-nvim];
      };

      extraLuaPackages = combineCatsOfFuncs extraLuaPackages;
      extraPythonPackages = combineCatsOfFuncs extraPythonPackages;
      extraPython3Packages = combineCatsOfFuncs extraPython3Packages;
    };
}
