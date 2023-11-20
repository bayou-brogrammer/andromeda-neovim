{
  pkgs,
  system,
  inputs,
  ...
}: let
  rootDir = "$PRJ_ROOT";
in
  pkgs.devshell.mkShell {
    devshell.name = "MilkyVim Shell";
    devshell.startup.preCommitHooks.text = inputs.self.checks.${system}.pre-commit-check.shellHook;

    packages = with pkgs; [
      fd
    ];

    commands = [
      {package = "nix-melt";}
      {package = "pre-commit";}
      {
        name = "fmt";
        help = "Check Nix formatting";
        command = "nix fmt \${@} ${rootDir}";
      }
      {
        name = "evalnix";
        help = "Check Nix parsing";
        command = "fd --extension nix --exec nix-instantiate --parse --quiet {} >/dev/null";
      }
    ];
  }
