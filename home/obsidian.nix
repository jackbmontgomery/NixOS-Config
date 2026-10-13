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
        vimMode = true;
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
      ];
    };

    vaults."Obsidian" = {
      enable = true;
      target = "Obsidian";
    };
  };
}
