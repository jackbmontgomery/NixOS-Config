{
  lib,
  pkgs,
  ...
}: let
  fallbackIpython = "${pkgs.python3.withPackages (ps: [ps.ipython ps.matplotlib ps.tkinter])}/bin/ipython";
in {
  programs.nvf.settings.vim = {
    extraPlugins.iron-nvim.package = pkgs.vimPlugins.iron-nvim;

    luaConfigRC.iron = {
      data = ''
        local iron = require("iron.core")
        local ll = require("iron.lowlevel")
        local common = require("iron.fts.common")
        local view = require("iron.view")

        local julia = "${lib.getExe pkgs.julia-bin}"

        local mpl_backend = "--InteractiveShellApp.exec_lines="
          .. [[exec("try:\n import matplotlib; matplotlib.use('TkAgg')\nexcept Exception: pass")]]

        local last_file = nil

        local function is_file_buf(buf)
          return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == ""
        end

        local function key_of(buf)
          local name = vim.api.nvim_buf_get_name(buf)
          if name ~= "" then
            return name
          end
          return "buf:" .. buf
        end

        local function current_key()
          local buf = vim.api.nvim_get_current_buf()
          if is_file_buf(buf) then
            last_file = key_of(buf)
          end
          return last_file or key_of(buf)
        end

        local buffer_scope = {
          set = function(memory, ft, repl)
            memory[ft] = memory[ft] or {}
            memory[ft][current_key()] = repl
            return repl
          end,
          get = function(memory, ft)
            memory[ft] = memory[ft] or {}
            return memory[ft][current_key()]
          end,
        }

        iron.setup({
          config = {
            scope = buffer_scope,
            scratch_repl = true,
            repl_open_cmd = view.split.botright.vertical("30%"),
            repl_definition = {
              -- command as a function so the environment is resolved from the
              -- buffer rather than from nvim's cwd. `--project=@.` walks up
              -- from the *process* working directory, and the REPL inherits
              -- nvim's, so `nvim ~/UCT/sandbox/Gadkari2019.jl` started from ~
              -- activates ~/.julia/environments/v1.12 instead of the sandbox.
              --
              -- The symptom is not a clean error. A different environment is a
              -- different dependency resolution, and the precompile cache is
              -- keyed on the whole resolution (compiled/v1.12/<pkg>/<pkg
              -- slug>_<config slug>.ji), so the same package gets built again
              -- from scratch under a new config slug: ~15 min for the SciML
              -- tree, repeated every time you launch nvim from a different
              -- directory. Same cwd bug the commented julia-languageserver cmd
              -- in languages.nix works around, measured there.
              julia = {
                command = function(meta)
                  local buf = meta.current_bufnr
                    or meta.current_buffer
                    or vim.api.nvim_get_current_buf()

                  local name = vim.api.nvim_buf_get_name(buf)
                  local from = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
                  -- Both names, to match the root_markers the jetls block
                  -- lists; Base.current_project() accepts either.
                  local proj = vim.fs.find(
                    { "JuliaProject.toml", "Project.toml" },
                    { path = from, upward = true, type = "file" }
                  )[1]
                  if proj ~= nil then
                    return { julia, "--project=" .. vim.fs.dirname(proj) }
                  end

                  -- No project above the file: @. degrades to the global
                  -- environment, which is the previous behaviour and the right
                  -- fallback for a scratch buffer.
                  return { julia, "--project=@." }
                end,
                env = {
                  QT_QPA_PLATFORM = "xcb",
                  QT_STYLE_OVERRIDE = "Fusion",
                },
                block_dividers = { "# %%", "#%%" },
              },
              python = {
                command = function(meta)
                  local buf = meta.current_bufnr
                    or meta.current_buffer
                    or vim.api.nvim_get_current_buf()

                 local name = vim.api.nvim_buf_get_name(buf)
                  local from = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
                  local venv = vim.fs.find(
                    { ".venv" },
                    { path = from, upward = true, type = "directory" }
                  )[1]
                  if venv ~= nil then
                    local ipython = venv .. "/bin/ipython"
                    if vim.uv.fs_stat(ipython) ~= nil then
                      return { ipython, "--no-autoindent", mpl_backend }
                    end
                  end

                  return { "${fallbackIpython}", "--no-autoindent", mpl_backend }
                end,
                env = {
                  MPLBACKEND = "TkAgg",
                  LD_LIBRARY_PATH = "${pkgs.libx11}/lib",
                },
                format = common.bracketed_paste_python,
                block_dividers = { "# %%", "#%%" },
              },
            },
          },
          keymaps = {
            toggle_repl = '<leader>rr', -- toggles the repl open and closed.
            restart_repl = '<leader>rR', -- calls `IronRestart` to restart the repl
            visual_send = '<leader>sc',
            send_line = '<leader>sl',
            send_code_block = '<leader>sb',
            send_code_block_and_move = '<leader>sn',
            exit = '<leader>rq',
            clear = '<leader>rc',
          },
        })

        local function sync_repl_windows()
          local key = current_key()
          local mine = nil
          for _, by_key in pairs(ll.store) do
            for k, meta in pairs(by_key) do
              if meta ~= nil and meta.bufnr ~= nil
                  and vim.api.nvim_buf_is_valid(meta.bufnr) then
                local win = vim.fn.bufwinid(meta.bufnr)
                if k == key then
                  mine = { meta = meta, win = win }
                elseif win ~= -1 then
                  pcall(vim.api.nvim_win_hide, win)
                end
              end
            end
          end
          if mine ~= nil and mine.win == -1 then
            pcall(iron.repl_for, vim.bo.filetype)
          end
        end

        -- A terminal buffer sends every key to the program, so nvim's own
        -- window motions never fire and there is no way back to the editor
        -- short of <C-\><C-n>. Scoped to filetype "iron" (which iron sets on
        -- its REPL buffers) so other terminals keep their keys.
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "iron",
          group = vim.api.nvim_create_augroup("ironTermKeys", { clear = true }),
          desc = "Let terminal-mode keys leave the iron REPL",
          callback = function(args)
            local function tmap(lhs, rhs)
              vim.keymap.set("t", lhs, rhs, { buffer = args.buf })
            end
            -- Straight from the REPL to the window in that direction.
            for _, d in ipairs({ "h", "j", "k", "l" }) do
              tmap("<C-" .. d .. ">", [[<C-\><C-n><C-w>]] .. d)
            end
            -- Normal mode within the REPL buffer, for scrolling back over
            -- output.
            tmap("<Esc>", [[<C-\><C-n>]])
          end,
        })

        vim.api.nvim_create_autocmd("BufEnter", {
          group = vim.api.nvim_create_augroup("ironOwnedRepls", { clear = true }),
          desc = "Show only the iron REPL belonging to the current file",
          callback = function(args)
            if not is_file_buf(args.buf) then
              return
            end
            -- Scheduled: hiding or opening a window from inside BufEnter is
            -- not allowed.
            vim.schedule(sync_repl_windows)
          end,
        })
      '';
      after = ["pluginConfigs"];
      before = [];
    };
  };
}
