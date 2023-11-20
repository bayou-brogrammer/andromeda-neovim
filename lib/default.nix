{lib, ...}: rec {
  # and this is the code from neovimUtils that it calls
  legacyWrapper = pkgs: neovim: {
    # except I also passed this through
    wrapRc ? true,
    extraName ? "",
    configure ? {},
    viAlias ? false,
    withRuby ? true,
    vimAlias ? false,
    withPython3 ? true,
    withNodeJs ? false,
    extraMakeWrapperArgs ? "",
    extraLuaPackages ? (_: []),
    extraPythonPackages ? (_: []),
    extraPython3Packages ? (_: []),
  }: let
    # and removed an error that doesnt make sense for my flake.
    plugins = pkgs.lib.flatten (pkgs.lib.mapAttrsToList genPlugin (configure.packages or {}));
    genPlugin = packageName: {
      opt ? [],
      start ? [],
    }:
      start
      ++ (map (p: {
          plugin = p;
          optional = true;
        })
        opt);

    res = pkgs.neovimUtils.makeNeovimConfig {
      customRC = configure.customRC or "";
      inherit plugins extraName withPython3;
      inherit withNodeJs withRuby viAlias vimAlias;
      inherit extraLuaPackages extraPython3Packages;
    };
  in
    pkgs.wrapNeovimUnstable neovim (res
      // {
        # and changed this
        inherit wrapRc;
        wrapperArgs =
          pkgs.lib.escapeShellArgs res.wrapperArgs
          + " "
          + extraMakeWrapperArgs;
      });

  # Source: https://github.com/NixOS/nixpkgs/blob/41de143fda10e33be0f47eab2bfe08a50f234267/pkgs/applications/editors/neovim/utils.nix#L24C9-L24C9
  # this is the code for wrapNeovim from nixpkgs
  wrapNeovim = pkgs: neovim-unwrapped:
    pkgs.lib.makeOverridable
    (legacyWrapper pkgs neovim-unwrapped);

  NeovimBuilder = {
    self,
    pkgs,
    settings ? {},
    neovimPlugins ? {},
    extraWrapperArgs ? {},
    lspsAndRuntimeDeps ? {},
    environmentVariables ? {},
    propagatedBuildInputs ? [],
    sources ? import ../nix/sources.nix,
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

    pluginDir = pkgs.linkFarm "nvim-plugins" (lib.mapAttrsToList (n: v: {
        name = n;
        path = v;
      })
      pkgs.neovimPlugins);

    parserDir = lib.milkyvim.generateTreesitterGrammar pkgs sources;

    # package the entire flake as plugin
    LuaConfig = pkgs.stdenv.mkDerivation {
      name = config.RCName;
      builder = pkgs.writeText "builder.sh" ''
        source $stdenv/setup
        mkdir -p $out
        cp -r ${self}/lua $out/lua

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
      (value: ''--prefix PATH : "${pkgs.lib.makeBinPath [value]}"'');

    # I didnt add stdenv.cc.cc.lib, so I would suggest not removing it.
    # It has cmake in it I think among other things?
    buildInputs = [pkgs.stdenv.cc.cc.lib] ++ propagatedBuildInputs;

    environmentVars =
      lib.mapAttrsToList (name: value: ''--set ${name} "${value}"'')
      (environmentVariables // {NVIM_PATH = "${LuaConfig}";});

    # cat our args
    extraMakeWrapperArgs = builtins.concatStringsSep " " (
      (wrapRuntimeDeps lspsAndRuntimeDeps)
      ++ environmentVars
      ++ extraWrapperArgs
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    );

    # add our propagated build dependencies
    myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
      propagatedBuildInputs = buildInputs;
    });

    # extraPythonPackages and the like require FUNCTIONS that return lists.
    # so we make a function that returns a function that returns lists.
    # this is used for the fields in the wrapper where the default value is (_: [])
    combineCatsOfFuncs = sect: (x: let
      appliedfunctions = builtins.map (value: value x) sect;
      combinedFuncRes = builtins.concatLists appliedfunctions;
      uniquifiedList = pkgs.lib.unique combinedFuncRes;
    in
      uniquifiedList);
  in
    # add our lsps and plugins and our config, and wrap it all up!
    wrapNeovim pkgs myNeovimUnwrapped {
      inherit wrapRc extraMakeWrapperArgs;
      inherit (config) vimAlias viAlias withRuby extraName withNodeJs withPython3;

      configure = {
        inherit customRC;
        packages.myVimPackage = {
          start = extraPlugins ++ [pkgs.neovimPlugins.lazy-nvim];
        };
      };

      extraLuaPackages = combineCatsOfFuncs extraLuaPackages;
      extraPythonPackages = combineCatsOfFuncs extraPythonPackages;
      extraPython3Packages = combineCatsOfFuncs extraPython3Packages;
    };
}
