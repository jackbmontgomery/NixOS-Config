{lib, ...}: {
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
    # {
    #   key = "<C-h>";
    #   mode = "n";
    #   action = "<C-w><C-h>";
    #   desc = "Move focus to the left window";
    # }
    # {
    #   key = "<C-l>";
    #   mode = "n";
    #   action = "<C-w><C-l>";
    #   desc = "Move focus to the right window";
    # }
    # {
    #   key = "<C-j>";
    #   mode = "n";
    #   action = "<C-w><C-j>";
    #   desc = "Move focus to the lower window";
    # }
    # {
    #   key = "<C-k>";
    #   mode = "n";
    #   action = "<C-w><C-k>";
    #   desc = "Move focus to the upper window";
    # }
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
  ];
}
