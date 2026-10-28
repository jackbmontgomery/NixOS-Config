{
  config,
  pkgs,
  lib,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};
  jsonFormat = pkgs.formats.json {};

  vscodeSettings =
    jsonFormat.generate "vscode-settings.json"
    config.programs.vscode.profiles.default.userSettings;

  marimo-vscode = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "marimo-team";
      name = "vscode-marimo";
      version = "0.18.3";
      arch = "linux-x64";
      sha256 = "1270vx0q6xjbl59pbhrjvp90iba2w1zmccwdk0cq8knnrg6d68xf";
    };
  };
in {
  xdg.configFile."marimo/marimo.toml".source = tomlFormat.generate "marimo.toml" {
    runtime = {
      auto_reload = "autorun";
      on_cell_change = "autorun";
      auto_instantiate = false;
      watcher_on_save = "autorun";
      reactive_tests = true;
      show_tracebacks = true;
    };
    keymap.preset = "vim";
    package_management.manager = "uv";
    formatting.line_length = 79;
    completion = {
      activate_on_typing = true;
      auto_close_pairs = true;
      copilot = false;
      signature_hint_on_typing = true;
    };
    display = {
      cell_output = "below";
      dataframes = "rich";
      default_width = "medium";
    };
    save = {
      autosave = "after_delay";
      autosave_delay = 1000;
      format_on_save = true;
    };
    server.browser = "default";
    ai.enabled = false;
  };

  # marimo hands ty the interpreter ms-python reports, which is not the project
  # venv; a ty config outranks that and `.venv` resolves per-project.
  xdg.configFile."ty/ty.toml".source = tomlFormat.generate "ty.toml" {
    environment.python = ".venv";
  };

  # Copied in rather than symlinked, so VSCode can write settings it needs to
  # persist. Nix re-asserts this content on every rebuild: UI changes are lost.
  home.file."${config.xdg.configHome}/Code/User/settings.json".enable = lib.mkForce false;

  home.activation.vscodeWritableSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    settingsPath="${config.xdg.configHome}/Code/User/settings.json"
    # rm first, or install follows the old symlink into the read-only store.
    $DRY_RUN_CMD rm -f "$settingsPath"
    $DRY_RUN_CMD install -Dm644 ${vscodeSettings} "$settingsPath"
  '';

  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions =
        [marimo-vscode]
        ++ (with pkgs.vscode-extensions; [
          mvllow.rose-pine
          ms-python.python
          charliermarsh.ruff
          vscodevim.vim
        ]);

      userSettings = {
        "workbench.colorTheme" = lib.mkForce "Rosé Pine";

        "workbench.editorAssociations"."*.py" = "marimo-notebook";
        "workbench.startupEditor" = "none";
        "workbench.activityBar.location" = "hidden";
        "workbench.layoutControl.enabled" = false;
        "workbench.editor.showTabs" = "single";
        "workbench.tips.enabled" = false;
        "window.menuBarVisibility" = "hidden";
        "window.commandCenter" = false;
        "window.restoreWindows" = "none";
        "breadcrumbs.enabled" = false;
        "editor.minimap.enabled" = false;
        "explorer.openEditors.visible" = 1;
        "git.enabled" = false;
        "telemetry.telemetryLevel" = "off";
        "security.workspace.trust.enabled" = false;

        "notebook.formatOnSave.enabled" = true;
        "notebook.codeActionsOnSave" = {
          "notebook.source.organizeImports" = "explicit";
        };
        "notebook.lineNumbers" = "on";
        "notebook.output.scrolling" = true;
        "notebook.globalToolbar" = true;
        "editor.lineNumbers" = "relative";
        "editor.inlayHints.enabled" = "off";
        "python.languageServer" = "None";

        "marimo.telemetry" = false;
        "marimo.uv.path" = lib.getExe pkgs.uv;
        "marimo.lsp.server" = "python";
        # unstable: marimo requires ruff >= 0.16.0 and ty >= 0.0.63.
        "marimo.ruff.path" = lib.getExe pkgs.unstable.ruff;
        "marimo.ty.path" = lib.getExe pkgs.unstable.ty;

        "chat.disableAIFeatures" = true;
        "github.copilot.enable"."*" = false;
        "editor.inlineSuggest.enabled" = false;

        "vim.useSystemClipboard" = true;
        "vim.hlsearch" = true;
        "vim.incsearch" = true;
        "vim.ignorecase" = true;
        "vim.smartcase" = true;

        "vim.normalModeKeyBindingsNonRecursive" = [
          {
            before = ["g" "n"];
            commands = ["editor.action.rename"];
          }
          {
            before = ["g" "r"];
            commands = ["references-view.findReferences"];
          }
          {
            before = ["<Esc>"];
            commands = [":noh"];
          }
        ];

        "editor.acceptSuggestionOnEnter" = "on";
        "editor.tabCompletion" = "off";
      };

      keybindings = [
        {
          key = "tab";
          command = "selectNextSuggestion";
          when = "suggestWidgetVisible && textInputFocus";
        }
        {
          key = "shift+tab";
          command = "selectPrevSuggestion";
          when = "suggestWidgetVisible && textInputFocus";
        }
        {
          key = "enter";
          command = "acceptSelectedSuggestion";
          when = "suggestWidgetVisible && textInputFocus";
        }
        {
          key = "d d";
          command = "notebook.cell.delete";
          when = "notebookEditorFocused && !inputFocus";
        }
        {
          key = "ctrl+enter";
          command = "notebook.cell.execute";
          when = "notebookEditorFocused";
        }
      ];
    };
  };
}
