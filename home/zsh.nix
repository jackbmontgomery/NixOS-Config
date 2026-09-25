{
  config,
  pkgs,
  lib,
  ...
}: let
  aphrodite = pkgs.fetchFromGitHub {
    owner = "win0err";
    repo = "aphrodite-terminal-theme";
    rev = "master";
    hash = "sha256-QGLjuxMIGg4z3/gov9H7/aHCv3tic+9SQuPcguZHB7o=";
  };
in {
  home.file.".oh-my-zsh/custom/themes/aphrodite".source = aphrodite;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    plugins = [
      {
        name = "aphrodite";
        file = "aphrodite.zsh-theme";
        src = pkgs.fetchFromGitHub {
          owner = "win0err";
          repo = "aphrodite-terminal-theme";
          rev = "master";
          sha256 = "sha256-QGLjuxMIGg4z3/gov9H7/aHCv3tic+9SQuPcguZHB7o=";
        };
      }
    ];

    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "timer"
      ];
    };

    shellAliases = {
      trash = "trash-put";

      # NixOS
      nrebuild = "sudo nixos-rebuild switch --flake ~/NixOS-Config#thinkpad";
      nupdate = "cd ~/NixOS-Config && nix flake update && sudo nixos-rebuild switch --flake ~/NixOS-Config#thinkpad";
      ncheck = "cd ~/NixOS-Config && nix flake check";
      ngc = "sudo nix-collect-garbage --delete-older-than 7d";

      # Git
      gs = "git status";
      ga = "git add .";
      gc = "git commit -m";
      gp = "git push";
      gl = "git log --oneline -10";
      gd = "git diff";

      # Python
      sp = "source .venv/bin/activate";
      py = "python3";
    };
  };
}
