{lib, ...}: {
  programs.nvf.settings.vim.utility = {
    guess-indent-nvim.enable = true;
    smart-splits.enable = true;
    oil-nvim = {
      enable = true;
      setupOpts = lib.mkLuaInline ''
        (function()
          -- split_path: ls-files prints paths relative to cwd, recursively.
          -- Oil only ever asks about names at the current level, so keep the
          -- first component. That also keeps a dot-directory visible when only
          -- its contents are known to git (.github/workflows/ci.yml -> .github).
          -- The ignored list is left alone: --directory already collapses wholly
          -- untracked directories, and an ignored file inside a tracked one
          -- (sub/out.log) must not be folded up into "sub".
          local function parse_output(proc, split_path)
            local result = proc:wait()
            local ret = {}
            if result.code == 0 then
              for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
                if split_path then
                  line = line:match("^[^/]+")
                else
                  -- Remove trailing slash
                  line = line:gsub("/$", "")
                end
                if line then
                  ret[line] = true
                end
              end
            end
            return ret
          end

          -- Lazily shells out to git the first time a directory is listed,
          -- then memoises the answer via rawset.
          local function new_git_status()
            return setmetatable({}, {
              __index = function(self, key)
                local ignore_proc = vim.system(
                  { "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
                  { cwd = key, text = true }
                )
                -- Upstream's recipe uses `git ls-tree HEAD --name-only`, which
                -- only sees the last commit: a staged or brand-new dotfile
                -- (.gitignore in a fresh repo, an .envrc you just wrote in oil)
                -- stays hidden until it is committed. --cached --others
                -- --exclude-standard is the index plus untracked-but-not-ignored
                -- instead, so the rule becomes "hide a dotfile only if git
                -- ignores it". git never lists .git itself, so it stays hidden.
                -- local tracked_proc = vim.system(
                --   { "git", "ls-tree", "HEAD", "--name-only" },
                --   { cwd = key, text = true }
                -- )
                local known_proc = vim.system(
                  { "git", "ls-files", "--cached", "--others", "--exclude-standard" },
                  { cwd = key, text = true }
                )
                local ret = {
                  ignored = parse_output(ignore_proc, false),
                  known = parse_output(known_proc, true),
                }

                rawset(self, key, ret)
                return ret
              end,
            })
          end

          local git_status = new_git_status()

          -- Clear the git status cache on refresh
          local refresh = require("oil.actions").refresh
          local orig_refresh = refresh.callback
          refresh.callback = function(...)
            git_status = new_git_status()
            orig_refresh(...)
          end

          return {
            columns = { "icon" },
            keymaps = {
              ["<C-s>"] = false,
              ["<C-h>"] = false,
            },
            lsp_file_methods = {
              autosave_changes = true,
            },
            view_options = {
              is_hidden_file = function(name, bufnr)
                local dir = require("oil").get_current_dir(bufnr)
                local is_dotfile = vim.startswith(name, ".") and name ~= ".."
                if not dir then
                  return is_dotfile
                end
                if is_dotfile then
                  return not git_status[dir].known[name]
                else
                  return git_status[dir].ignored[name]
                end
              end,
            },
          }
        end)()
      '';
    };
  };
}
