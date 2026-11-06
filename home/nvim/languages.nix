{
  lib,
  pkgs,
  inputs,
  ...
}: let
  jetls = import ./jetls.nix {inherit pkgs inputs;};
in {
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
        hover = "gh";
        openDiagnosticFloat = "ge";
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

        fatou = {
          cmd = [(lib.meta.getExe pkgs.unstable.fatou) "lsp"];
          filetypes = ["julia"];
          root_markers = ["Project.toml" "JuliaProject.toml" ".git"];
        };

        jetls = {
          cmd = [(lib.meta.getExe jetls) "serve"];
          filetypes = ["julia"];
          root_markers = ["Project.toml" "JuliaProject.toml"];
        };
      };
    };

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
      julia = {
        enable = true;
        lsp.enable = false;
      };
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

    luaConfigRC.jetls = ''
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client == nil or client.name ~= "jetls" then
            return
          end

          client.server_capabilities.documentFormattingProvider = nil
          client.server_capabilities.documentRangeFormattingProvider = nil

          local inner = client.supports_method
          client.supports_method = function(self, method, ...)
            if method == "textDocument/formatting" or method == "textDocument/rangeFormatting" then
              return false
            end
            return inner(self, method, ...)
          end
        end,
      })
    '';
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
