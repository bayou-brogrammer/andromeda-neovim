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

        outputs-builder = channels: {
          # packages.default = nixCats;
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
      url = "git+file:///home/n16hth4wk/dev/nixos/andromeda-lib";
      # url = "https://flakehub.com/f/milkyway-org/andromeda-lib/0.1.*.tar.gz";
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
