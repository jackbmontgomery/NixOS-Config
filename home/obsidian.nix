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
        "command-palette"
        "file-explorer"
        "global-search"
        "graph"
        "outline"
        "page-preview"
        "properties"
        "tag-pane"
        "templates"
        "word-count"
        "workspaces"
      ];
    };

    vaults."Obsidian" = {
      enable = true;
      target = "Obsidian";
    };
  };
}
