{
  description = "Jake Hamilton's Neovim configuration";

  outputs = inputs: let
    milkyvim = {
      inherit inputs;

      src = ./.;
      channels-config.allowUnfree = true;

      andromeda = {
        namespace = "milkyvim";
      };
    };
  in
    inputs.andromeda.lib.mkFlake (milkyvim
      // {
        ###########
        # OVERLAYS
        ###########
        overlays = with inputs; [
          devshell.overlays.default
          nixd.outputs.overlays.default
        ];

        ##########
        # ALIAS
        ##########
        alias = {
          shells.default = "milkyvim-shell";
        };

        outputs-builder = channels: let
          pkgs = channels.nixpkgs;
          inherit (inputs.self) lib;

          # Now that our plugin inputs/overlays and pkgs have been defined,
          # We define a function to facilitate package building for particular categories
          # what that function does is it intakes a set of categories
          # with a boolean value for each, and a set of settings
          # and then it imports NeovimBuilder.nix, passing it that categories set but also
          # our other information. This allows us to define our categories later.
          nixVimBuilder = settings: (lib.NeovimBuilder {
            inherit pkgs settings;
            inherit (inputs) self;
            inherit (pkgs) neovimPlugins;

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
            nixCats = {
              wrapRc = true;
              viAlias = true;
              vimAlias = true;
              RCName = "milkyvim";
            };
          };

          nixCats = nixVimBuilder settings.nixCats;
        in {
          packages.default = nixCats;
          formatter = channels.nixpkgs.alejandra;

          checks.pre-commit-check = inputs.pre-commit-hooks.lib.${channels.nixpkgs.system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true;
              deadnix.enable = true;
              nil.enable = true;
              prettier.enable = true;
              statix.enable = true;
            };
          };
        };
      });

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";

    nixvim = {
      url = "https://flakehub.com/f/nix-community/nixvim/0.1.*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    andromeda = {
      # url = "git+file:///home/n16hth4wk/dev/nixos/andromeda-lib";
      url = "https://flakehub.com/f/milkyway-org/andromeda-lib/0.1.*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # a flake import. We will import this one with an overlay
    # but you could also import the package itself instead.
    # overlays are just nice if they are offered.
    nixd.url = "https://flakehub.com/f/nix-community/nixd/1.2.*.tar.gz";
  };

  inputs = {
    # Core
    "plugins-lazy-nvim" = {
      url = "github:folke/lazy.nvim";
      flake = false;
    };

    # Core
    "plugins-catppuccin.nvim" = {
      url = "github:catppuccin/nvim";
      flake = false;
    };
  };

  #***********************
  #* DEVONLY INPUTS
  #***********************
  inputs = {
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/*.tar.gz";
    flake-compat = {
      url = "https://flakehub.com/f/edolstra/flake-compat/*.tar.gz";
      flake = false;
    };

    # Gitignore common input
    gitignore = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hercules-ci/gitignore.nix";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        gitignore.follows = "gitignore";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };

    systems.url = "github:nix-systems/default";
  };
}
