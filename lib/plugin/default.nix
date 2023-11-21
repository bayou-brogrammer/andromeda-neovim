{lib, ...}: let
  inherit (lib) mapAttrs' mapAttrs nameValuePair filterAttrs hasPrefix removePrefix replaceStrings;
  inherit (lib.milkyvim) genAttrs';
in {
  # -------------- #
  # {Plugin}
  # -------------- #

  getPluginName = input:
    builtins.substring
    (builtins.stringLength "plugins-")
    (builtins.stringLength input)
    input;

  generateNeovimPlugins = pkgs: sources: let
    buildPlugin = name: source:
      pkgs.vimUtils.buildVimPlugin {
        src = source;
        name = "${name}-${source.rev}";
        namePrefix = ""; # Clear name prefix
      };

    generatedPluginSources =
      mapAttrs'
      (n: v: nameValuePair (builtins.replaceStrings ["plugin-"] [""] n) v)
      (filterAttrs (n: _: hasPrefix "plugin-" n) sources);

    generatedPlugins =
      mapAttrs buildPlugin generatedPluginSources;

    neovimPlugins =
      generatedPlugins
      // {
        # Add plugins you want synced with nixpkgs here, or override
        # existing ones from the generated plugin set.
        inherit (pkgs.vimPlugins) nvim-treesitter nvim-treesitter-textobjects nvim-treesitter-refactor;
      };
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
