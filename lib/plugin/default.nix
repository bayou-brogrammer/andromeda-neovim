{lib, ...}: {
  # -------------- #
  # {Plugin}
  # -------------- #
  generateNeovimPlugins = pkgs: neovimPlugins:
    pkgs.linkFarm "nvim-plugins" (lib.mapAttrsToList (n: v: {
        name = n;
        path = v;
      })
      neovimPlugins);

  # -------------- #
  # {Parser}
  # -------------- #
  generateTreesitterGrammar = pkgs: treesitterParsers:
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
