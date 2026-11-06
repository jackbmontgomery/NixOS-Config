{
  lib,
  pkgs,
  ...
}: let
  julia = lib.getExe pkgs.julia-bin;
  ss = "${pkgs.iproute2}/bin/ss";

  nvim-smuggler = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-smuggler";
    version = "0-unstable-2026-04-21";
    src = pkgs.fetchFromGitHub {
      owner = "klafyvel";
      repo = "nvim-smuggler";
      rev = "92110b4840b4841f020ebd20cdd889624a56373d";
      hash = "sha256-J01xhIMzXbu7uYY7iUCUYbvH/dVihA1jJ8L9Rgek66o=";
    };
    # Upstream ships no rockspec in-tree (it is published to luarocks
    # separately), so the dependency list is taken from the `require` calls in
    # lua/smuggler: "nio" is a hard require, "image" is guarded behind
    # config.image_nvim_available() and so stays optional.
    dependencies = [pkgs.vimPlugins.nvim-nio];
    nvimRequireCheck = "smuggler";
  };

  # Launching Julia through a script rather than inlining the command into
  # `tmux split-window` keeps the `smuggle(...)` string out of two layers of
  # shell quoting, and gives the stale-socket cleanup somewhere to live.
  smuggle-repl = pkgs.writeShellScript "smuggle-repl" ''
    root="$1"
    socket="$2"

    # A socket file outlives the REPL that created it. REPLSmuggler's
    # SocketSmuggler calls Sockets.listen(path) and never unlinks the path
    # itself; libuv only unlinks on a clean close, so a Julia killed with
    # SIGKILL (or a lost tmux server) leaves the file on disk. Measured: after
    # `kill -9` the path is still a socket, while `ss -lx src <path>` reports
    # no listener -- which is exactly the split the liveness probe in the lua
    # below relies on. The next listen() on that name then fails with
    # EADDRINUSE, so the file has to go before Julia starts.
    rm -f "$socket"

    # Record which pane this REPL is in, so <leader>rq can kill it. $TMUX_PANE
    # is set by tmux inside the new pane, which makes this the pane's own
    # answer rather than something guessed from `list-panes` output.
    #
    # Deliberately *not* beside the socket: nvim-smuggler's
    # utils.getavailablesockets() returns every entry of the sockets directory
    # without filtering, so a sidecar file in there would show up in the
    # picker as a socket that cannot be connected to.
    panedir="$3"
    mkdir -p "$panedir"
    pane="$panedir/$(basename "$socket")"
    echo "$TMUX_PANE" > "$pane"

    # REPLSmuggler lives in the global environment, not in "$root" -- see the
    # comment on the activation script in home/julia.nix for why that resolves.
    ${julia} --project="$root" -i -e "using REPLSmuggler; smuggle(\"$(basename "$socket")\")"
    status=$?

    rm -f "$pane"

    # Julia exiting closes the pane, which would take any startup error with
    # it before it could be read. Hold the pane open on failure only, so a
    # deliberate `exit()` still cleans up after itself.
    if [ "$status" -ne 0 ]; then
      echo
      echo "julia exited with status $status -- press enter to close this pane"
      read -r _
    fi
  '';
in {
  programs.nvf.settings.vim = {
    extraPlugins.nvim-nio.package = pkgs.vimPlugins.nvim-nio;
    extraPlugins.nvim-smuggler.package = nvim-smuggler;

    luaConfigRC.smuggler = {
      data = ''
        local buffers = require("smuggler.buffers")
        local utils = require("smuggler.utils")

        ----------------------------------------------------------------------
        -- Socket naming
        ----------------------------------------------------------------------
        -- `smuggle()` with no argument picks a random name ("contraband_
        -- clandestine_operation"), and nvim-smuggler's default socket picker
        -- lists the whole runtime directory. With two Julia REPLs alive that
        -- turns every send into a vim.ui.select prompt in which nothing says
        -- which REPL belongs to which project.
        --
        -- Naming the socket after the project instead makes that mapping
        -- total: the picker below filters to the one socket belonging to the
        -- current buffer's project, and `autoselect_single_socket` then takes
        -- it without prompting. One REPL per project, reached with no
        -- questions asked -- the same per-scope ownership the old iron config
        -- built by hand, but keyed on the environment rather than the file.

        local function project_root(buf)
          local name = vim.api.nvim_buf_get_name(buf)
          local from = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
          -- Both names, to match the root_markers the jetls block lists;
          -- Base.current_project() accepts either.
          local proj = vim.fs.find(
            { "JuliaProject.toml", "Project.toml" },
            { path = from, upward = true, type = "file" }
          )[1]
          if proj ~= nil then
            return vim.fs.dirname(proj)
          end
          -- No project above the file: the REPL gets --project=<dir>, which is
          -- the scratch-buffer fallback.
          return from
        end

        local function socket_name(root)
          -- The basename alone is not unique (every checkout of the same
          -- package shares it), so it is only the readable half -- it is what
          -- you see in the picker if the filter ever falls through. The other
          -- half disambiguates: 8 hex chars is 32 bits, against the handful of
          -- sockets one user has live at once.
          local label = vim.fs.basename(root):gsub("[^%w._-]", "_")
          return label .. "-" .. vim.fn.sha256(root):sub(1, 8)
        end

        local function socket_path(root)
          return utils.socketsdir() .. socket_name(root)
        end

        -- The socket file's presence says nothing about whether a REPL is
        -- behind it (see the stale-socket comment in smuggle-repl). `ss` asks
        -- the kernel for listeners instead, which is both accurate and free of
        -- side effects -- probing by connecting would work too, but every
        -- probe would print "New client connected" / "REPL client exited" into
        -- the Julia pane.
        local function socket_live(path)
          if vim.uv.fs_stat(path) == nil then
            return false
          end
          local res = vim.system({ "${ss}", "-lxH", "src", path }, { text = true }):wait()
          return res.code == 0 and res.stdout:match("%S") ~= nil
        end

        -- Where smuggle-repl records the tmux pane id of each REPL. Kept out
        -- of the sockets directory on purpose -- see the comment in
        -- smuggle-repl for why a sidecar in there would break the picker.
        local panedir = vim.fs.joinpath(vim.env.XDG_RUNTIME_DIR, "nvim-smuggler-panes")

        local function sockets_for_buffer()
          local path = socket_path(project_root(vim.api.nvim_get_current_buf()))
          if socket_live(path) then
            return { path }
          end
          -- No REPL for this project: fall back to the listing, so a
          -- `smuggle()` started by hand in some other pane is still reachable.
          -- Filtered, because getavailablesockets() returns directory entries
          -- without checking any of them, and offering a socket whose REPL is
          -- gone just moves the failure to the connect.
          return vim.iter(utils.getavailablesockets()):filter(socket_live):totable()
        end

        ----------------------------------------------------------------------
        -- Setup
        ----------------------------------------------------------------------
        require("smuggler").setup({
          buffers = {
            availablesockets = sockets_for_buffer,
            autoselect_single_socket = true,
            -- false: each top-level statement in a sent chunk is evaluated
            -- separately and gets its own result, so a multi-line send yields
            -- one piece of virtual text per statement rather than one for the
            -- whole block. That per-statement feedback is the point of the
            -- plugin; :SmuggleEvalByBlocks flips it per session when a chunk
            -- needs to share scope.
            eval_by_blocks = false,
          },
          ui = {
            -- Rendering images needs image.nvim, which is not installed. With
            -- this true the session still asks Julia to write PNGs to showdir
            -- and send back paths that nothing can draw, so turn the request
            -- off at the source rather than relying on the guarded require.
            display_images = false,
            qf_auto_refresh = true,
            qf_auto_open = false,
          },
          log = {
            -- use_file defaults to false in config.lua (upstream's own
            -- log.lua defaults it to true, so the plugin's defaults disagree
            -- with each other), which means warnings and connection failures
            -- went nowhere persistent -- vim.notify only, and with noice that
            -- is a popup that can disappear before it is read. nvim.log does
            -- not help either: it carries libuv/TUI messages, not plugin Lua
            -- output, and ours holds nothing but terminal-mode warnings.
            --
            -- Logging to $XDG_DATA_HOME/nvim/smuggler.log instead, so a fault
            -- that only shows up mid-session leaves a timestamped record.
            -- "warn" keeps it to warn/error/fatal; "trace" logs every msgpack
            -- decode attempt and grows fast.
            use_file = true,
            use_console = true,
            level = "warn",
          },
        })

        ----------------------------------------------------------------------
        -- Guard ui.add_window against stale window ids
        ----------------------------------------------------------------------
        -- Fixes a recurring "Invalid window id: NNNN" from ui.lua:285.
        --
        -- setup() installs a global, unscoped WinNew autocmd (ui.init_ui) that
        -- does:
        --
        --   local winid = math.max(unpack(vim.api.nvim_list_wins()))
        --   vim.schedule(function() ui.add_window(winid) end)
        --
        -- and add_window opens with an unguarded nvim_win_get_buf(winid). The
        -- call is deferred, so any window that opens and closes inside one
        -- tick is already gone when it runs, and the lookup throws. Reproduced
        -- exactly -- same stack trace -- with `vim.cmd("split")` followed
        -- immediately by `vim.cmd("close")`.
        --
        -- It fires on every WinNew in the editor, not just Julia buffers, so
        -- the real sources here are the transient floats: noice messages and
        -- cmdline, telescope, which-key, blink-cmp's completion menu. Nothing
        -- to do with the REPL, which is why it looked unrelated to sending
        -- code.
        --
        -- Wrapped rather than patched: the autocmd calls `ui.add_window`
        -- through the module table, so replacing the field intercepts it, and
        -- an upstream fix would simply make this check redundant instead of
        -- conflicting with a patch file.
        --
        -- Worth knowing that `math.max` over every window id is a guess at
        -- "the window just created" rather than a fact about it. Left alone:
        -- with the id validated, the worst case is image bookkeeping attached
        -- to the wrong live window, and add_an_image_to_result returns
        -- immediately while display_images is false.
        local smuggler_ui = require("smuggler.ui")
        local add_window = smuggler_ui.add_window
        smuggler_ui.add_window = function(winid)
          if not vim.api.nvim_win_is_valid(winid) then
            return
          end
          return add_window(winid)
        end

        ----------------------------------------------------------------------
        -- Making REPL errors visible
        ----------------------------------------------------------------------
        -- The diagnostics arrive correctly without this -- vim.diagnostic.get
        -- holds the exception with its stacktrace mapped back to the right
        -- file and line -- but nothing on screen says so. This config has
        -- signs, virtual_text and virtual_lines all false globally, leaving
        -- `underline` as the only cue, so a REPL error reads as a faint
        -- squiggle you have to hover to identify. For an LSP that is a
        -- defensible quiet default; for the REPL it hides the one thing the
        -- round trip was for.
        --
        -- Scoped to smuggler's namespace rather than changed globally, so
        -- jetls, texlab and the linters keep the understated treatment they
        -- have now. vim.diagnostic.set() in ui.lua uses the namespace called
        -- "smuggler"; creating it here by the same name returns that same id
        -- (nvim_create_namespace is get-or-create).
        -- Wrap the message, because nothing else will.
        --
        -- set_one_diagnostic in ui.lua builds a single line with no newlines
        -- in it -- "[N] " .. exception text .. " in " .. frame -- and a Julia
        -- MethodError carries full type signatures, so it routinely runs past
        -- the window edge. Neither built-in renderer wraps: measured on a
        -- 260-character message in a 90-column window, virtual_text truncates
        -- at the edge, and virtual_lines only moves the same truncation to the
        -- line below, cutting mid-token.
        --
        -- The `format` hook is the way in. The renderer splits whatever string
        -- it returns on newlines and lays each one out as its own virtual
        -- line, so the wrapping has to happen in here.
        local function wrap_diagnostic(diagnostic)
          local win = vim.api.nvim_get_current_win()
          -- textoff is the measured width of the number/sign/fold gutter, so
          -- this is the real text area rather than a guess at it. The 6 is the
          -- renderer's own "|____ " prefix, which it reuses as the
          -- continuation indent on every line after the first.
          local width = vim.api.nvim_win_get_width(win)
            - vim.fn.getwininfo(win)[1].textoff
            - 6
          -- A narrow split should still break somewhere readable instead of
          -- degenerating to one word per line.
          width = math.max(width, 30)

          local pieces = {}
          for word in diagnostic.message:gmatch("%S+") do
            -- A Julia type signature is frequently one unbroken token wider
            -- than the window (Matrix{ComplexF64}, long parameter lists).
            -- Hard-break those: leaving them to overflow is the problem being
            -- fixed. Display width rather than byte length, since exception
            -- text can carry operators like ≤ and ∘.
            while vim.fn.strdisplaywidth(word) > width do
              pieces[#pieces + 1] = vim.fn.strcharpart(word, 0, width)
              word = vim.fn.strcharpart(word, width)
            end
            pieces[#pieces + 1] = word
          end

          local lines, line = {}, ""
          for _, word in ipairs(pieces) do
            if line == "" then
              line = word
            elseif vim.fn.strdisplaywidth(line .. " " .. word) <= width then
              line = line .. " " .. word
            else
              lines[#lines + 1] = line
              line = word
            end
          end
          if line ~= "" then
            lines[#lines + 1] = line
          end
          return table.concat(lines, "\n")
        end

        vim.diagnostic.config({
          underline = true,
          -- Severity in the sign column, message wrapped underneath. The
          -- stacktrace itself is longer than is worth inlining, so it stays in
          -- the quickfix list that qf_auto_refresh keeps populated -- :copen
          -- after an error, or <leader>cq below.
          signs = true,
          virtual_text = false,
          virtual_lines = { format = wrap_diagnostic },
        }, vim.api.nvim_create_namespace("smuggler"))

        -- Re-wrap after a resize, because format runs once per render and the
        -- result is cached in the extmark. Measured: a message wrapped for a
        -- 100-column window and then resized to 64 keeps its old break points
        -- and loses its tail to clipping -- the original complaint, back again.
        -- vim.diagnostic.show() re-runs format and restores it.
        --
        -- Driven per window through nvim_win_call so that the width
        -- wrap_diagnostic measures belongs to the window holding the buffer,
        -- rather than whichever window happened to be current when the resize
        -- fired.
        vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
          group = vim.api.nvim_create_augroup("smugglerRewrap", { clear = true }),
          desc = "Re-wrap smuggler diagnostics after a resize",
          callback = function()
            local ns = vim.api.nvim_create_namespace("smuggler")
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              if #vim.diagnostic.get(buf, { namespace = ns }) > 0 then
                vim.api.nvim_win_call(win, function()
                  vim.diagnostic.show(ns, buf)
                end)
              end
            end
          end,
        })

        ----------------------------------------------------------------------
        -- Launcher
        ----------------------------------------------------------------------
        local function launch()
          if vim.env.TMUX == nil then
            return vim.notify("smuggler: not running inside tmux", vim.log.levels.ERROR)
          end

          local buf = vim.api.nvim_get_current_buf()
          local root = project_root(buf)
          local path = socket_path(root)

          if socket_live(path) then
            -- Already running. Connecting is idempotent (buffers.buffer
            -- returns the existing session unless forced), so this is the
            -- "attach this buffer too" case for a second file in the project.
            buffers.buffer(buf, false)
            return vim.notify("smuggler: attached to " .. vim.fs.basename(path))
          end

          vim.system({
            "tmux", "split-window",
            "-h",         -- beside the editor, matching the old iron layout
            "-d",         -- focus stays in nvim; C-l reaches the pane when needed
            "-l", "40%",
            "-c", root,
            "${smuggle-repl}", root, path, panedir,
          }):wait()

          -- Wait on the socket, not on the Julia process: the pane is detached
          -- so there is no pid to watch, and the socket appearing is the
          -- actual precondition for connecting.
          --
          -- 250ms is well under human notice for a REPL that takes seconds to
          -- boot. The 180s ceiling covers a cold start -- startup.jl pulls in
          -- Revise, OhMyREPL and AbbreviatedStackTraces before `-e` even runs,
          -- and the first launch after a Julia version bump precompiles all of
          -- them. It is a giving-up bound, not an expected wait.
          local waited, interval, limit = 0, 250, 180000
          local timer = vim.uv.new_timer()
          timer:start(interval, interval, vim.schedule_wrap(function()
            if socket_live(path) then
              timer:stop()
              timer:close()
              buffers.buffer(buf, true)
              vim.notify("smuggler: connected to " .. vim.fs.basename(path))
              return
            end
            waited = waited + interval
            if waited >= limit then
              timer:stop()
              timer:close()
              vim.notify(
                "smuggler: no socket after " .. (limit / 1000) .. "s -- check the Julia pane",
                vim.log.levels.ERROR
              )
            end
          end))
        end

        -- Send the enclosing `# %%` cell. nvim-smuggler has no cell concept of
        -- its own; this reproduces the block_dividers the old iron config used
        -- for both Julia and Python, so `# %%` markers already in the files
        -- keep working.
        local function send_cell()
          local divider = "^%s*#%s*%%%%"
          local cur = vim.api.nvim_win_get_cursor(0)[1]
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

          local first = 1
          for i = cur, 1, -1 do
            if lines[i]:match(divider) then
              first = i + 1
              break
            end
          end

          local last = #lines
          for i = cur + 1, #lines do
            if lines[i]:match(divider) then
              last = i - 1
              break
            end
          end

          if first > last then
            return vim.notify("smuggler: empty cell", vim.log.levels.WARN)
          end
          vim.cmd(first .. "," .. last .. "SmuggleRange")
        end

        -- Tear the REPL down. :SmuggleExit alone is not enough and is easy to
        -- misread as doing this: its server-side handler
        -- (Server.treatrequest(::Val{:exit}, ...)) interrupts the backend and
        -- calls close(session), but serve_repl keeps looping `while
        -- isopen(smuggler)`, so Julia stays alive in the pane with the socket
        -- still bound. Killing the pane is what actually ends the process --
        -- which is the point of the key, since a fresh REPL is the only way
        -- past a const or struct redefinition.
        local function quit()
          local path = socket_path(project_root(vim.api.nvim_get_current_buf()))
          local pane = vim.fs.joinpath(panedir, vim.fs.basename(path))

          pcall(vim.cmd, "SmuggleExit")

          local id = nil
          local f = io.open(pane, "r")
          if f ~= nil then
            id = vim.trim(f:read("*l") or "")
            f:close()
          end
          if id == nil or id == "" then
            return vim.notify(
              "smuggler: session closed, but no pane recorded for "
                .. vim.fs.basename(path)
                .. " -- close it by hand",
              vim.log.levels.WARN
            )
          end

          vim.system({ "tmux", "kill-pane", "-t", id }):wait()
          -- kill-pane signals the process group, so Julia never gets to
          -- unlink the socket; smuggle-repl's rm -f covers that on relaunch.
          os.remove(pane)
          vim.notify("smuggler: killed " .. vim.fs.basename(path) .. " in pane " .. id)
        end

        vim.keymap.set("n", "<leader>rr", launch, { desc = "Julia REPL: launch or attach (smuggler)" })
        vim.keymap.set("n", "<leader>rq", quit, { desc = "Julia REPL: exit session" })
        -- Visual-mode send, replacing the default mapping, which silently
        -- sends one line instead of the selection.
        --
        -- Upstream maps visual <leader>cs to `<Cmd>SmuggleRange<cr>`, and
        -- <Cmd> does not behave like `:` in visual mode: it neither prepends
        -- the '<,'> range nor leaves the visual marks set. Measured on a
        -- two-line selection of lines 1-2, cursor on 1:
        --
        --   <Cmd>Probe<cr>    line1=2 line2=2   '<=0 '>=0
        --   :<C-u>Probe<cr>   line1=1 line2=1   '<=1 '>=2
        --   :Probe<cr>        line1=1 line2=2   '<=1 '>=2
        --
        -- So the default sends only the cursor line -- and sends the wrong one
        -- at that, since line2=2 is where the cursor ended up, not where the
        -- selection started.
        --
        -- :SmuggleVisual is the command written for this case, and it needs
        -- both halves of that table. Its body is
        --
        --   send_range(buf, cmdargs.line1, cmdargs.line2,
        --              getpos("'<")[3], getpos("'>")[3], visualmode())
        --
        -- so the *lines* come from the command range while the marks supply
        -- only the *columns* -- which is what lets it keep charwise and
        -- blockwise selections intact instead of rounding them to whole
        -- lines. A plain `:` is therefore required: it both inserts the
        -- '<,'> range and leaves the marks set. `:<C-u>` would strip the
        -- range and collapse the send back to the cursor line (measured:
        -- line1=line2=1 for a selection of 1-2), and <Cmd> gives neither.
        vim.keymap.set("v", "<leader>cs", ":SmuggleVisual<cr>", { desc = "Smuggle the visual selection" })

        vim.keymap.set("n", "<leader>cb", send_cell, { desc = "Smuggle enclosing # %% cell" })
        -- The inline message is one line; this is where the stacktrace is.
        vim.keymap.set("n", "<leader>cq", "<cmd>SmuggleQuickFix<cr>", { desc = "Smuggler stacktrace in quickfix" })
      '';
      after = ["pluginConfigs"];
      before = [];
    };
  };
}
