{
  lib,
  pkgs,
  ...
}: let
  # Derived rather than written out so it follows the julia-bin in nixpkgs:
  # the global environment directory is named after the minor version, so a
  # 1.12 -> 1.13 bump has to land in a fresh ~/.julia/environments/v1.13.
  juliaEnv = "v${lib.versions.majorMinor pkgs.julia-bin.version}";
in {
  home.sessionVariables.JULIA_EDITOR = "nvim";
  home.sessionVariables.JULIA_PKG_PRESERVE_TIERED_INSTALLED = "true";
  # home.sessionVariables.JULIA_STACKTRACE_ABBREVIATED = "true";

  home.file.".julia/config/startup.jl".text = ''
    try
        using Revise
        using OhMyREPL
        using AbbreviatedStackTraces
    catch e
        @warn "Error loading QoL packages" exception=(e, catch_backtrace())
    end
  '';

  # REPLSmuggler is what nvim-smuggler talks to, so every Julia REPL launched
  # for an editor session needs to be able to load it -- including REPLs
  # started with --project=<some package checkout>, whose Project.toml will
  # never list it.
  #
  # The global environment is what makes that work: LOAD_PATH is
  # ["@", "@v#.#", "@stdlib"], so a `using` that the active project cannot
  # satisfy falls through to ~/.julia/environments/v#.#. That is the same
  # mechanism that already lets startup.jl above load Revise and OhMyREPL from
  # inside any project, so REPLSmuggler goes in beside them rather than into
  # each project.
  #
  # The grep guard keeps this off the critical path of every switch: Pkg.add
  # is idempotent but costs a Julia start (~2s warm) to find that out, whereas
  # reading the Project.toml costs nothing and answers the same question.
  home.activation.juliaReplSmuggler = lib.hm.dag.entryAfter ["writeBoundary"] ''
    globalProject="$HOME/.julia/environments/${juliaEnv}/Project.toml"
    if ! ${pkgs.gnugrep}/bin/grep -q '^REPLSmuggler = ' "$globalProject" 2>/dev/null; then
      # --startup-file=no: startup.jl loads Revise/OhMyREPL, which this does
      # not need and which would only slow the one-off install down.
      run ${lib.getExe pkgs.julia-bin} --startup-file=no \
        --project="@${juliaEnv}" \
        -e 'using Pkg; Pkg.add("REPLSmuggler")'
    fi
  '';
}
