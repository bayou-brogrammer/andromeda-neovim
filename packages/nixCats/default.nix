{
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Now that our plugin inputs/overlays and pkgs have been defined,
  # We define a function to facilitate package building for particular categories
  # what that function does is it intakes a set of categories
  # with a boolean value for each, and a set of settings
  # and then it imports NeovimBuilder.nix, passing it that categories set but also
  # our other information. This allows us to define our categories later.
  nixVimBuilder = settings: (lib.milkyvim.NeovimBuilder {
    inherit (pkgs) neovimPlugins treesitterParsers;
    inherit (inputs) self;
    inherit pkgs settings;

    # propagatedBuildInputs:
    # this section is for dependencies that should be available
    # at BUILD TIME for plugins. WILL NOT be available to PATH
    # However, they WILL be available to the shell
    # and neovim path when using nix develop
    propagatedBuildInputs = [];

    # lspsAndRuntimeDeps:
    # this section is for dependencies that should be available
    # at RUN TIME for plugins. Will be available to path within neovim terminal
    # this includes LSPs
    lspsAndRuntimeDeps = with pkgs; [
      fd
      ripgrep
      universal-ctags

      # nix-doc tags will make your tags much better in nix
      # but only if you have nil as well for some reason
      nil
      nixd
      lua-language-server
    ];

    # environmentVariables:
    # this section is for environmentVariables that should be available
    # at RUN TIME for plugins. Will be available to path within neovim terminal
    environmentVariables = {};

    # If you know what these are, you can provide custom ones by category here.
    # If you dont, check this link out:
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    extraWrapperArgs = [];
    extraLuaPackages = [];
    extraPythonPackages = [];
    extraPython3Packages = [];
  });

  settings = {
    wrapRc = true;
    viAlias = true;
    vimAlias = true;
    RCName = "milkyvim";
  };
in
  nixVimBuilder settings
