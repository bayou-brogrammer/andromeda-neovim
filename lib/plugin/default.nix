{lib, ...}: let
  inherit (lib) mapAttrs filterAttrs hasPrefix removePrefix replaceStrings;
  inherit (lib.milkyvim) genAttrs';
in rec {
  # -------------- #
  # {Plugin}
  # -------------- #

  getPluginName = input:
    builtins.substring
    (builtins.stringLength "plugins-")
    (builtins.stringLength input)
    input;

  generateNeovimPlugins = pkgs: sources: let
    inherit (pkgs.vimUtils) buildVimPlugin;

    plugins =
      builtins.filter
      (s: (builtins.match "plugins-.*" s) != null)
      (builtins.attrNames sources);

    buildPlug = name:
      buildVimPlugin {
        version = "master";
        pname = getPluginName name;
        src = builtins.getAttr name sources;
      };

    neovimPlugins = builtins.listToAttrs (map
      (plugin: {
        value = buildPlug plugin;
        name = getPluginName plugin;
      })
      plugins);
  in
    pkgs.linkFarm "nvim-plugins" (lib.mapAttrsToList (n: v: {
        name = n;
        path = v;
      })
      neovimPlugins);

  # -------------- #
  # {Parser}
  # -------------- #
  generateTreesitterGrammar = pkgs: sources: let
    # Grammar builder function
    buildGrammar = pkgs.callPackage "${pkgs}/pkgs/development/tools/parsing/tree-sitter/grammar.nix" {};

    # Build grammars that were fetched using nvfetcher
    generatedGrammars = mapAttrs (n: v:
      buildGrammar {
        language = removePrefix "tree-sitter-" n;
        inherit (v) version src;
      }) (filterAttrs (n: _: hasPrefix "tree-sitter-" n) sources);

    # Attrset of grammars built using nvim-treesitter's lockfile
    grammars' =
      genAttrs' pkgs.vimPlugins.nvim-treesitter.withAllGrammars.passthru.dependencies
      (v: replaceStrings ["vimplugin-treesitter-grammar-"] ["tree-sitter-"] v.name);

    treesitterParsers = grammars' // generatedGrammars;
  in
    pkgs.linkFarm
    "treesitter-parsers"
    (lib.mapAttrsToList
      (n: v: let
        name = "${lib.replaceStrings ["-"] ["_"] (lib.removePrefix "tree-sitter-" n)}.so";
      in {
        inherit name;
        path =
          # nvim-treesitter's grammars are inside a "parser" directory, which sucks
          if lib.hasPrefix "vimplugin-treesitter" v.name
          then "${v}/parser/${name}"
          else "${v}/parser";
      })
      treesitterParsers);
}
