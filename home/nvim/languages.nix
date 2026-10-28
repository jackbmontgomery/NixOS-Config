{
  lib,
  pkgs,
  ...
}: {
  programs.nvf.settings.vim = {
    lsp = {
      enable = true;
      formatOnSave = true;
      presets = {
        harper.enable = true;
      };
      mappings = {
        renameSymbol = "gn";
        codeAction = "ga";
        goToDefinition = null;
        goToType = null;
        listImplementations = null;
        listReferences = null;
        listDocumentSymbols = null;
        listWorkspaceSymbols = null;
      };
      servers = {
        basedpyright.settings.basedpyright.analysis = {
          typeCheckingMode = "standard";
        };
        texlab.settings.texlab = {
          build = {
            executable = "latexmk";
            args = ["-pdf" "-interaction=nonstopmode" "-synctex=1" "%f"];
            onSave = true;
            forwardSearchAfter = true;
          };
          forwardSearch = {
            executable = "zathura";
            args = ["--synctex-forward" "%l:1:%f" "%p"];
          };
        };
        harper = {
          filetypes = ["markdown" "tex"];
          settings."harper-ls" = {
            dialect = "British";
          };
        };

        julia-languageserver.cmd = lib.mkForce (lib.generators.mkLuaInline ''
          {
            '${lib.meta.getExe (pkgs.julia-bin.withPackages ["LanguageServer"])}',
            '--startup-file=no',
            '--history-file=no',
            '-e',
            [[
              using LanguageServer

              project_path = dirname(something(
                  Base.current_project(),
                  Base.load_path_expand("@v#.#"),
              ))
              depot_path = ""
              symserver_store_path = joinpath(homedir(), ".cache", "julia-symbolcache")
              mkpath(symserver_store_path)

              @info "Running language server" VERSION pwd() project_path symserver_store_path
              server = LanguageServer.LanguageServerInstance(
                  stdin, stdout, project_path, depot_path, nothing, symserver_store_path,
              )
              server.runlinter = true
              run(server)
            ]],
          }
        '');
      };
    };
    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
      julia.enable = true;
      tex.enable = true;
      markdown = {
        enable = true;
        lsp.servers = ["rumdl"];
        format.type = ["rumdl"];
        extensions.render-markdown-nvim = {
          enable = true;
          setupOpts = {
            latex.enabled = false;
          };
        };
      };
      lua.enable = true;
      python = {
        enable = true;
        format.type = ["ruff" "ruff-fix"];
        lsp.servers = ["basedpyright" "ruff"];
        extraDiagnostics.enable = false;
      };
    };

    formatter.conform-nvim.setupOpts.formatters.rumdl.append_args = [
      "--config"
      ''global.flavor = "obsidian"''
      "--config"
      "MD013.line-length = 80"
      "--config"
      "MD013.reflow = true"
      "--config"
      ''MD013.reflow-mode = "normalize"''
    ];
  };

  programs.ruff = {
    enable = true;
    settings = {
      lint = {
        unfixable = ["F401"];
        extend-ignore = ["F722"];
      };
    };
  };
}
