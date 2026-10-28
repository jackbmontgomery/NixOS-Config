{
  config,
  pkgs,
  ...
}: let
  # Plain julia-bin, deliberately not julia-bin.withPackages: the extension
  # bootstraps its own environment under the first depot
  # (~/.julia/environments/vscode_pluto_notebook/<version>) and runs
  # Pkg.Registry.add + Pkg.add("Pluto") + Pkg.instantiate there on every
  # launch -- see src/server/bootstrap.ts. A withPackages depot is a
  # read-only store path, so that Pkg.add would fail.
  julia = "${pkgs.julia-bin}/bin/julia";

  # juliapluto-pankgeorg.advanced-vscode-extension lists both of these in
  # extensionDependencies. VSCode disables an extension outright when a
  # declared dependency is missing, so neither is optional: without them the
  # notebook type is never registered and *.pluto.jl opens as plain text.
  # language-julia comes from nixpkgs (1.215.2, slightly behind the
  # marketplace's 1.250.2); the auth extension is not packaged there.
  juliahub-auth = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "JuliaComputing";
      name = "juliahub-vscode-auth";
      version = "0.1.15";
      sha256 = "1xrp8idgc5av1ln9vfp8anlf48xwg45932rxcp1x71nwj43ii48n";
    };
  };

  pluto-vscode = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "juliapluto-pankgeorg";
      name = "advanced-vscode-extension";
      version = "0.11.1";
      sha256 = "0nhvpi6mkv31g68agwr74f0s40wc9fkihv6xrndjnmard1rgyljd";
    };
  };

  # Using a project's own code from a notebook: load it as a package, never
  # include() it. An `include("src/Gadkari2019.jl")` cell, where that file
  # starts with `module Gadkari2019`, fails on re-run with
  #
  #   cannot declare workspace#17.Gadkari2019 constant;
  #   it was already declared as an import
  #
  # because the include tries to bind a module constant in Pluto's workspace,
  # while Pluto manages workspace bindings itself and already holds the name
  # as an import -- and include is opaque to its reactive analysis, so it
  # cannot sequence around it. Instead give the package a src/<Pkg>.jl that
  # includes the submodules, and open the notebook with:
  #
  #   begin
  #       import Pkg
  #       Pkg.activate(@__DIR__)
  #       using Revise
  #       using BES
  #   end
  #
  # then reach things as `BES.Gadkari2019.Model()`. Two consequences:
  #
  #   * Pkg.activate switches the notebook off Pluto's built-in package
  #     manager and onto the project's Manifest, so notebook and scripts share
  #     one set of versions. Package code must then declare stdlibs in [deps]
  #     (LinearAlgebra, say) -- a script gets them free via Main's load path.
  #   * Re-running the `using` cell never reloads edited source: the package
  #     is already loaded in the notebook's worker process. Measured against
  #     BES.jl -- a function edited from 1 to 99 still returned 1 after
  #     re-running every cell, and returned 99 once Revise was loaded first.
  #     Revise redefines methods only; a changed struct field still needs
  #     "Pluto: Restart Server", which restarts every notebook on the shared
  #     server.

  # Pluto's counterpart to `mo`. Two jobs, both of which have to happen before
  # VSCode sees the file:
  #
  #   1. Scaffold. The extension's deserializer throws on a file with no cell
  #      markers and falls back to one cell holding the parse error ("Invalid
  #      or missing cell ID", plutoSerializer.ts). It has no scaffold-on-open
  #      path, so an empty `.pluto.jl` can only be fixed before opening.
  #   2. Open the *folder*, not just the file -- the Pluto server is a
  #      vscode.TaskScope.Workspace task and never starts in a folderless
  #      window.
  #
  # A scaffolded notebook also gets the activation cell above pre-filled,
  # since every notebook needs it (each one is a separate worker process, so
  # activation never carries over) and `using <Pkg>` cannot work without it.
  # The package name, the `Pkg.activate` spelling and whether Revise is
  # available are all read off the nearest Project.toml, searching upward from
  # the notebook -- so a notebook beside Project.toml gets
  # `Pkg.activate(@__DIR__)`, a nested one gets the current_project form, and
  # a notebook outside any project gets the bare one-empty-cell skeleton
  # rather than an activation line that would silently create an empty env.
  #
  # Both skeletons are byte-identical to what Pluto.save_notebook writes for
  # the same cells, verified by round-tripping them back through
  # Pluto.load_notebook, so generating them needs no Julia in the closure.
  pl = pkgs.writeShellScriptBin "pl" ''
    set -euo pipefail
    if [ "$#" -lt 1 ]; then
        echo "usage: pl <notebook.pluto.jl>" >&2
        exit 1
    fi
    case "$1" in
        *.pluto.jl | *.dyad.jl) ;;
        *)
            echo "pl: name must end in .pluto.jl or .dyad.jl, the only patterns the extension opens as notebooks" >&2
            exit 1
            ;;
    esac
    # -m: the notebook need not exist yet, pl is also how you create one.
    file="$(${pkgs.coreutils}/bin/realpath -m "$1")"
    dir="$(${pkgs.coreutils}/bin/dirname "$file")"
    # -s rather than -f: a touched 0-byte file is the case that fails, and it
    # looks identical to a missing one as far as Pluto is concerned.
    if [ ! -s "$file" ]; then
        # Nearest enclosing project, searched upward like Base.current_project.
        proj=""
        probe="$dir"
        while [ "$probe" != "/" ]; do
            if [ -f "$probe/Project.toml" ]; then
                proj="$probe"
                break
            fi
            probe="$(${pkgs.coreutils}/bin/dirname "$probe")"
        done

        preamble=""
        if [ -n "$proj" ]; then
            name="$(${pkgs.gnused}/bin/sed -n 's/^name *= *"\([^"]*\)".*/\1/p' "$proj/Project.toml" | ${pkgs.coreutils}/bin/head -1)"
            if [ -n "$name" ]; then
                if [ "$proj" = "$dir" ]; then
                    activate="Pkg.activate(@__DIR__)"
                else
                    activate="Pkg.activate(dirname(Base.current_project(@__DIR__)))"
                fi
                # Assembled by two single-line printf calls rather than one
                # multi-line shell string: a shell string spanning lines
                # inside this Nix string gets its continuation lines
                # re-indented by alejandra, which silently rewrites the
                # Julia it emits. Every literal here stays on one line.
                #
                # Revise is only offered when the project actually depends
                # on it, otherwise the very first cell would fail to load.
                if ${pkgs.gnused}/bin/sed -n '/^\[deps\]/,/^\[/p' "$proj/Project.toml" | ${pkgs.gnugrep}/bin/grep -q '^Revise *='; then
                    preamble="$(${pkgs.coreutils}/bin/printf 'begin\n    import Pkg\n    %s\n    using Revise\n    using %s\nend' "$activate" "$name")"
                else
                    preamble="$(${pkgs.coreutils}/bin/printf 'begin\n    import Pkg\n    %s\n    using %s\nend' "$activate" "$name")"
                fi
            fi
        fi

        # printf rather than a heredoc: a heredoc body has to be the
        # least-indented lines in this Nix string to survive multiline-string
        # indent stripping, with its terminator at column 0 -- which any reformat
        # silently breaks.
        #
        # The `# v` line is informational -- Pluto rewrites it with its own
        # version on first save, so it need not track the Pluto the extension
        # installs.
        id1="$(${pkgs.util-linux}/bin/uuidgen)"
        id2="$(${pkgs.util-linux}/bin/uuidgen)"
        {
            ${pkgs.coreutils}/bin/printf '### A Pluto.jl notebook ###\n# v1.1.0\n\nusing Markdown\nusing InteractiveUtils\n\n'
            # Cell bodies: marker, code, one blank line. Empty code therefore
            # lands as marker plus two blank lines, which is what Pluto emits.
            ${pkgs.coreutils}/bin/printf '# ╔═╡ %s\n%s\n\n' "$id1" "$preamble"
            if [ -n "$preamble" ]; then
                ${pkgs.coreutils}/bin/printf '# ╔═╡ %s\n%s\n\n' "$id2" ""
            fi
            ${pkgs.coreutils}/bin/printf '# ╔═╡ Cell order:\n# ╠═%s\n' "$id1"
            if [ -n "$preamble" ]; then
                ${pkgs.coreutils}/bin/printf '# ╠═%s\n' "$id2"
            fi
        } > "$file"
        if [ -n "$preamble" ]; then
            echo "pl: scaffolded $file (activating $name)"
        else
            echo "pl: scaffolded $file (no enclosing project, empty notebook)"
        fi
    fi
    exec ${config.programs.vscode.package}/bin/code "$dir" "$file"
  '';
in {
  home.packages = [pl];

  programs.vscode.profiles.default = {
    extensions = [
      pluto-vscode
      juliahub-auth
      pkgs.vscode-extensions.julialang.language-julia
    ];

    userSettings = {
      # The extension resolves Julia from the Julia extension's API, then from
      # this setting, then from `julia` on PATH (src/julia-utils.ts). The
      # juliaup the README asks for is only needed for JuliaHub's Dyad
      # channels, so a nixpkgs julia is enough.
      "julia.executablePath" = julia;

      "pluto-notebook.notebookBrowser" = "embedded";

      # The Pluto server runs as a vscode.TaskScope.Workspace task
      # (plutoServerTask.ts), so it only starts in a window that has a folder
      # open. Open a notebook as a lone file and there is no server: cells
      # queue forever with "Server not running" in the Pluto Controller log
      # and no error in the UI. Setting `pluto-notebook.serverUrl` to an
      # externally started server is the way out if that ever bites.

      # Off: this otherwise runs an HTTP server on 3100 for AI clients the
      # whole time a notebook is open. Flip it on to let Claude Code drive a
      # notebook over MCP.
      "pluto-notebook.autoStartMcpServer" = false;

      # Only *.pluto.jl and *.dyad.jl open as notebooks -- that selector is
      # the extension's own (contributes.notebooks), so an existing Pluto
      # notebook named plain `foo.jl` opens as text until it is renamed.
      # `*.jl` cannot be associated globally the way *.py is for marimo,
      # because that would hijack every Julia source file. To keep a
      # directory of plain-.jl notebooks working instead of renaming them:
      #
      #   "workbench.editorAssociations"."**/notebooks/*.jl" = "pluto-notebook";
      #
      # One-off: command palette -> "View: Reopen Editor With..." -> Pluto
      # Notebook.
    };
  };
}
