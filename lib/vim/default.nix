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
    res = pkgs.neovimUtils.makeNeovimConfig {
      inherit extraLuaPackages extraPython3Packages extraPythonPackages;
      inherit withNodeJs withRuby withPython3;
      inherit extraName viAlias vimAlias;

      plugins = configure.plugins or [];
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
}
