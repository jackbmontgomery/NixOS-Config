{ config, pkgs, ... }:
{
    programs.zsh = 
    {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        oh-my-zsh = 
        {
            enable = true;
            theme = "bira"; 
            plugins = 
            [
                "git"
                "sudo"
                "timer"
            ];
        };

        shellAliases = 
        {
            trash = "trash-put";

            # NixOS
            nrebuild = "sudo nixos-rebuild switch --flake ~/NixOS-Config#thinkpad";
            nupdate = "cd ~/NixOS-Config && nix flake update && sudo nixos-rebuild switch --flake ~/NixOS-Config#thinkpad";
            ncheck = "cd ~/NixOS-Config && nix flake check";
            ngc = "sudo nix-collect-garbage --delete-older-than 7d";

            gs = "git status";
            ga = "git add .";
            gc = "git commit -m";
            gp = "git push";
            gl = "git log --oneline -10";
            gd = "git diff";
        };
    };
}
