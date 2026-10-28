{lib, ...}: {
  # nvim 0.12 ships grn/gra/grx/grr/gri/grt by default. Any of those makes a
  # bare `gr` ambiguous, so it would only fire after `timeoutlen`. Rename and
  # references now live on gn/gr (languages.nix, default.nix); code action,
  # implementations and type definitions keep their <leader>l* bindings. Only
  # grx (codelens) loses its key, which nothing here was using.
  programs.nvf.settings.vim.luaConfigRC.dropDefaultLspMaps = {
    data = ''
      for _, lhs in ipairs({"grn", "gra", "grx", "grr", "gri", "grt"}) do
        -- pcall: vim.keymap.del throws when the mapping is already absent.
        pcall(vim.keymap.del, "n", lhs)
        pcall(vim.keymap.del, "x", lhs)
      end
    '';
    after = [];
    before = ["pluginConfigs" "lazyConfigs"];
  };

  programs.nvf.settings.vim.keymaps = [
    {
      key = "-";
      mode = "n";
      silent = true;
      action = "<CMD>Oil<CR>";
      desc = "Open Parent Directory";
    }
    {
      key = "<Esc>";
      mode = "n";
      silent = true;
      action = "<cmd>nohlsearch<CR>";
      desc = "Clear search";
    }
    {
      key = "<left>";
      mode = "n";
      action = "<cmd>echo 'Use h to move!!'<CR>";
    }
    {
      key = "<right>";
      mode = "n";
      action = "<cmd>echo 'Use l to move!!'<CR>";
    }
    {
      key = "<up>";
      mode = "n";
      action = "<cmd>echo 'Use k to move!!'<CR>";
    }
    {
      key = "<down>";
      mode = "n";
      action = "<cmd>echo 'Use j to move!!'<CR>";
    }
    {
      key = "<leader>on";
      mode = "n";
      silent = true;
      lua = true;
      action = ''
        function()
          vim.ui.input({ prompt = "Note title: " }, function(title)
            if title and title ~= "" then
              vim.cmd("Obsidian new " .. title)
            end
          end)
        end
      '';
      desc = "[O]bsidian new [n]ote";
    }
    {
      key = "<leader>op";
      mode = "n";
      silent = true;
      lua = true;
      action = ''
        function()
          vim.ui.input({ prompt = "Name: " }, function(name)
            if name and name ~= "" then
              vim.cmd("Obsidian new People/" .. name)
            end
          end)
        end
      '';
      desc = "[O]bsidian new [p]erson";
    }
    {
      key = "<leader>or";
      mode = "n";
      silent = true;
      lua = true;
      action = ''
        function()
          vim.ui.input({ prompt = "Title: " }, function(title)
            if title and title ~= "" then
              vim.cmd("Obsidian new Papers/" .. title)
            end
          end)
        end
      '';
      desc = "[O]bsidian new [r]esearch paper";
    }
    {
      key = "<leader>lv";
      mode = "n";
      silent = true;
      lua = true;
      action = ''
        function()
          local client = vim.lsp.get_clients({ bufnr = 0, name = "texlab" })[1]
          if not client then
            return vim.notify("texlab is not attached to this buffer", vim.log.levels.WARN)
          end
          -- texlab/build are custom LSP methods with no built-in Neovim
          -- handler, so one must be passed explicitly or request() errors.
          client:request(
            "textDocument/forwardSearch",
            vim.lsp.util.make_position_params(0, client.offset_encoding),
            function(err, result)
              if err then
                return vim.notify("forward search: " .. err.message, vim.log.levels.ERROR)
              end
              -- status 0 is success. Non-zero usually means there is no PDF or
              -- synctex data yet, so build once (<leader>lb or :w) and retry.
              if result and result.status ~= 0 then
                vim.notify(
                  ("forward search failed (status %d) - try building first"):format(result.status),
                  vim.log.levels.WARN
                )
              end
            end,
            0
          )
        end
      '';
      desc = "[L]aTeX [v]iew (forward search)";
    }
    {
      key = "<leader>lb";
      mode = "n";
      silent = true;
      lua = true;
      action = ''
        function()
          local client = vim.lsp.get_clients({ bufnr = 0, name = "texlab" })[1]
          if not client then
            return vim.notify("texlab is not attached to this buffer", vim.log.levels.WARN)
          end
          client:request(
            "textDocument/build",
            { textDocument = vim.lsp.util.make_text_document_params(0) },
            function(err, result)
              if err then
                return vim.notify("build: " .. err.message, vim.log.levels.ERROR)
              end
              -- status 0 is success; non-zero means latexmk errored, and the
              -- details land in diagnostics.
              if result and result.status == 0 then
                vim.notify("build succeeded", vim.log.levels.INFO)
              else
                vim.notify(
                  ("build failed (status %d) - see diagnostics"):format(result and result.status or -1),
                  vim.log.levels.ERROR
                )
              end
            end,
            0
          )
        end
      '';
      desc = "[L]aTeX [b]uild";
    }
  ];
}
