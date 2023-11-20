{lib, ...}:
with lib;
with lib.milkyvim; rec {
  # -------------- #
  # {Parser}
  # -------------- #
  generateTreesitterGrammar = pkgs: sources: let
    # Grammar builder function
    buildGrammar = pkgspkgs.callPackage "${inputs.nixpkgs}/pkgs/development/tools/parsing/tree-sitter/grammar.nix" {};

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
    grammars = grammars' // generatedGrammars;
  in
    pkgs.linkFarm
    "treesitter-parsers"
    (mapAttrsToList
      (n: v: let
        name = "${replaceStrings ["-"] ["_"] (removePrefix "tree-sitter-" n)}.so";
      in {
        inherit name;
        path =
          # nvim-treesitter's grammars are inside a "parser" directory, which sucks
          if hasPrefix "vimplugin-treesitter" v.name
          then "${v}/parser/${name}"
          else "${v}/parser";
      })
      grammars);

  # -------------- #
  # {Plugin}
  # -------------- #

  generatedPluginSources = sources:
    mapAttrs'
    (n: v: nameValuePair (builtins.replaceStrings ["plugin-"] [""] n) v)
    (filterAttrs (n: _: hasPrefix "plugin-" n) sources);

  generatePlugins = pkgs: sources: let
    buildPlugin = name: source:
      pkgs.vimUtils.buildVimPlugin {
        name = "${name}-${source.rev}";
        namePrefix = ""; # Clear name prefix
        src = source;
      };

    generatedPlugins = with lib;
      mapAttrs buildPlugin (generatedPluginSources sources);

    plugins =
      generatedPlugins
      // {
        # Add plugins you want synced with nixpkgs here, or override
        # existing ones from the generated plugin set.
        inherit (pkgs.vimPlugins) nvim-treesitter nvim-treesitter-textobjects nvim-treesitter-refactor;
      };
  in
    pkgs.linkFarm "nvim-plugins" (mapAttrsToList (n: v: {
        name = n;
        path = v;
      })
      plugins);
}
# pluginDir = lib.milkyvim.generatePlugins pkgs sources;
# parserDir = lib.milkyvim.generateTreesitterGrammar pkgs sources;

