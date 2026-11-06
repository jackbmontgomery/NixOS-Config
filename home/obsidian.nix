{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.obsidian = {
    enable = true;

    defaultSettings = {
      app = {
        alwaysUpdateLinks = true;
        spellcheck = true;
        vimMode = false;
      };

      corePlugins = [
        "backlink"
        "command-palette"
        "file-explorer"
        "global-search"
        "graph"
        "outline"
        "page-preview"
        "properties"
        "tag-pane"
        {
          name = "templates";
          settings = {
            folder = "Templates";
            dateFormat = "DD-MMM-YYY";
            timeFormat = "HH:mm";
          };
        }
        "word-count"
        "workspaces"
        "slides"
        "switcher"
        "slash-command"
        "sync"
      ];
      communityPlugins = with pkgs.obsidianPlugins; [
        vim-motions
      ];
    };

    vaults."Obsidian" = {
      enable = true;
      target = "Obsidian";
    };
  };

  home.file."Obsidian/.obsidian.init.lua".text = ''
    vim.g.mapleader = " "
    vim.opt.number = true
    vim.opt.relativenumber = true
  '';
}
