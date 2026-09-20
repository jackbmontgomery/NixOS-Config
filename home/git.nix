{ config, lib, pkgs, ... }:
{
    programs.git = {
        enable = true;
        settings = {
            user = {
                name = "Jack Montgomery";
                email = "mail@jackbmontgomery.com";
            };
            init.defaultBranch = "main";
            core.editor = "nvim";
            pull.rebase = true;
        };
    };
}
