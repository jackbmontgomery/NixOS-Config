{
  config,
  pkgs,
  inputs,
  ...
}: let
  jetls = import ./nvim/jetls.nix {inherit pkgs inputs;};
  julia = "${pkgs.julia-bin}/bin/julia";

  juliahub-auth = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "JuliaComputing";
      name = "juliahub-vscode-auth";
      version = "0.1.15";
      sha256 = "1xrp8idgc5av1ln9vfp8anlf48xwg45932rxcp1x71nwj43ii48n";
    };
  };

  jetls-client = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "aviatesk";
      name = "jetls-client";
      version = "2026.10.26";
      sha256 = "1hfqj8yga6qphhma2qz8dm2ykyvxxbjj933744xsc9wyyk4ar2ab";
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

  pl = pkgs.writeShellScriptBin "pl" ''
    set -euo pipefail
    if [ "$#" -lt 1 ]; then
        echo "usage: pl <notebook.pluto.jl>" >&2
        exit 1
    fi
    case "$1" in
        *.pluto.jl) ;;
        *)
            echo "pl: name must end in .pluto.jl" >&2
            exit 1
            ;;
    esac
    file="$(${pkgs.coreutils}/bin/realpath -m "$1")"
    dir="$(${pkgs.coreutils}/bin/dirname "$file")"
    project=""
    probe="$dir"
    while [ "$probe" != "/" ]; do
        if [ -f "$probe/Project.toml" ] || [ -f "$probe/JuliaProject.toml" ]; then
            project="$probe"
            break
        fi
        probe="$(${pkgs.coreutils}/bin/dirname "$probe")"
    done

    if [ ! -s "$file" ]; then
        id0="$(${pkgs.util-linux}/bin/uuidgen)"
        id1="$(${pkgs.util-linux}/bin/uuidgen)"
        {
            ${pkgs.coreutils}/bin/printf '### A Pluto.jl notebook ###\n# v1.1.0\n\nusing Markdown\nusing InteractiveUtils\n\n'
            ${pkgs.coreutils}/bin/printf '# ╔═╡ %s\nbegin\n    import Pkg\n    project = Base.current_project(@__DIR__)\n    if project === nothing\n        Pkg.activate(@__DIR__)\n    else\n        Pkg.activate(dirname(project))\n    end\nend\n\n' "$id0"
            ${pkgs.coreutils}/bin/printf '# ╔═╡ %s\n\n\n' "$id1"
            ${pkgs.coreutils}/bin/printf '# ╔═╡ Cell order:\n'
            ${pkgs.coreutils}/bin/printf '# ╟─%s\n' "$id0"
            ${pkgs.coreutils}/bin/printf '# ╠═%s\n' "$id1"
        } > "$file"
        if [ -n "$project" ]; then
            echo "pl: scaffolded $file, activating $project"
        else
            echo "pl: scaffolded $file, activating $dir (new sandbox; Pkg.add there to fill it)"
        fi
    fi
    exec ${config.programs.vscode.package}/bin/code "''${project:-$dir}" "$file"
  '';
in {
  home.packages = [pl];

  programs.vscode.profiles.default = {
    extensions = [
      pluto-vscode
      juliahub-auth
      jetls-client
      pkgs.vscode-extensions.julialang.language-julia
    ];

    userSettings = {
      # The extension resolves Julia from the Julia extension's API, then from
      # this setting, then from `julia` on PATH (src/julia-utils.ts). The
      # juliaup the README asks for is only needed for JuliaHub's Dyad
      # channels, so a nixpkgs julia is enough.
      "julia.executablePath" = julia;

      # Upstream defaults this to true, which runs an HTTP server on 3100 for
      # AI clients the whole time a notebook is open. Flip it back on to let
      # Claude Code drive a notebook over MCP.
      #
      # (`pluto-notebook.notebookBrowser` is not set: "embedded" is already
      # its default.)
      "pluto-notebook.autoStartMcpServer" = false;

      # Array form is "a full custom command", which is the point: it bypasses
      # the extension's managed installation, which would otherwise Pkg.add
      # JETLS into its own depot under VSCode's global storage -- a second copy
      # of a server this machine already has in the store, resolved against
      # juliaup rather than nixpkgs. The wrapper forwards "$@", so the
      # `--pipe=` that vscode-languageclient appends reaches JETLS intact.
      "jetls-client.executable" = ["${jetls}/bin/jetls" "serve"];

      # Same decision as nvim, same reason: the inferred-type ghost text after
      # every binding and call is unwanted, and hover reports the type on
      # demand anyway. See home/nvim/languages.nix luaConfigRC.jetls.
      "jetls-client.settings" = {
        inlay_hint.types.enabled = false;
      };

      # Two Julia servers now run here, and that is not optional:
      # julialang.language-julia is an extensionDependency of the Pluto
      # extension, so LanguageServer.jl starts whether or not JETLS does.
      # Unlike nvim -- where vim.lsp.buf.format applies every client that
      # advertises formatting, in undefined order, hence the capability
      # stripping in languages.nix -- VSCode has explicit tiebreakers, so the
      # split is declared rather than enforced:
      #
      #   LanguageServer.jl  formatting (it bundles JuliaFormatter)
      #   JETLS              hover, completion, navigation, diagnostics
      #
      # Formatting goes to language-julia deliberately. JETLS does not format
      # anything itself -- its Runic preset shells out to a `runic` on PATH,
      # and this configuration has no such executable (see the commented-out
      # wrapper in home/nvim/languages.nix), so pointing the default formatter
      # at jetls-client would fail every format-on-save with "runic not found".
      "[julia]"."editor.defaultFormatter" = "julialang.language-julia";

      # LanguageServer.jl has no notebook awareness whatsoever -- zero matches
      # for "notebook" in its source -- so the Pluto extension's cells reach it
      # as unrelated single-cell documents via the vscode-notebook-cell scheme
      # its client selector accepts. Per-cell lint from a server that cannot
      # see the other cells, next to JETLS's whole-notebook diagnostics, is
      # duplication at best. julia.lint.missingrefs already defaults to "none",
      # so this is not what keeps cross-cell references from being flagged.
      "julia.lint.run" = false;
      "julia.inlayHints.static.enabled" = false;
      "julia.inlayHints.runtime.enabled" = false;

      # Only *.pluto.jl and *.dyad.jl open as notebooks, per the extension's
      # own contributes.notebooks, so a Pluto notebook named plain `foo.jl`
      # opens as text until renamed -- `*.jl` cannot be associated globally
      # the way *.py is for marimo without hijacking every Julia source file.
      # Per-directory escape hatch, if a folder of plain-.jl notebooks ever
      # needs to keep its names:
      #
      #   "workbench.editorAssociations"."**/notebooks/*.jl" = "pluto-notebook";
    };
  };
}
