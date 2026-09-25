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
      };

      corePlugins = [
        "backlink"
        "bookmarks"
        "daily-notes"
        "file-explorer"
        "global-search"
        "templates"
      ];
    };

    vaults."Jack Montgomery" = {
      enable = true;
      target = "Documents/Obsidian/Jack Montgomery";
    };
  };
}
