{
  lib,
  inputs,
  channels,
  ...
}: final: _prev:
with lib;
with lib.milkyvim; let
  pkgs = channels.nixpkgs;

  # Grammar builder function
  buildGrammar = pkgs.callPackage "${final}/pkgs/development/tools/parsing/tree-sitter/grammar.nix" {};

  # Build grammars that were fetched using nvfetcher
  generatedGrammars = mapAttrs (n: v:
    buildGrammar {
      language = removePrefix "tree-sitter-" n;
      inherit (v) version src;
    }) (filterAttrs (n: _: hasPrefix "tree-sitter-" n) inputs);

  # Attrset of grammars built using nvim-treesitter's lockfile
  grammars' =
    genAttrs' pkgs.vimPlugins.nvim-treesitter.withAllGrammars.passthru.dependencies
    (v: replaceStrings ["vimplugin-treesitter-grammar-"] ["tree-sitter-"] v.name);
in {
  treesitterParsers = grammars' // generatedGrammars;
}
