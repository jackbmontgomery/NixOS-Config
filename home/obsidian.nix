{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.obsidian = {
    enable = true;

    vaults.notes.target = "~/Documents/Obsidian/Jack Montgomery";

    defaultSettings.app = {
      alwaysUpdateLinks = true;
      spellcheck = true;
    };

    defaultSettings.corePlugins = [
      "backlink"
      "bookmarks"
      "daily-notes"
      "file-explorer"
      "global-search"
      "templates"
    ];
  };
}
