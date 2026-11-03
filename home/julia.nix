{...}: {
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
}
