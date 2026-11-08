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
        # The centered column; the width itself comes from the CSS snippet below.
        readableLineLength = true;
      };

      # Merged with the snippet stylix contributes, not a replacement for it.
      cssSnippets = [
        {
          name = "Line width";
          text = ''
            /* Readable line length centres the column via margin:auto on
               .cm-sizer / .markdown-preview-sizer; --file-line-width only sets
               its max-width, so widening this keeps the centring. Obsidian
               declares the 700px default on body, and snippets load after
               app.css, so this wins. 1ch is the width of "0": in a
               proportional font 100ch comfortably clears prettier's
               100-character wrap without the column ever being the
               constraint. */
            body {
              --file-line-width: 100ch;
            }
          '';
        }
      ];

      appearance = {
        showViewHeader = false;
        showRibbon = false;
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
        {
          pkg = obsidian-hider;
          settings = {
            hideStatus = false;
            hideTabs = true;
            hideScroll = true;
            hideSidebarButtons = false;
            hideTooltips = false;
            hideFileNavButtons = false;
            hideSearchSuggestions = false;
            hideSearchCounts = false;
            hideInstructions = false;
            hidePropertiesReading = false;
            hideVault = false;
          };
        }
        format-with-prettier
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
    vim.opt.textwidth = 100
    vim.opt.clipboard = "unnamedplus"
  '';

  home.file."Obsidian/prettierrc.json".source = (pkgs.formats.json {}).generate "prettierrc.json" {
    proseWrap = "always";
    printWidth = 100;
    tabWidth = 4;
    useTabs = true;
  };
}
