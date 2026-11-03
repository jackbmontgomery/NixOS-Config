# The patched JETLS, as a plain function file rather than a module: two
# clients need the same derivation and neither should own it -- nvim via
# home/nvim/languages.nix, and VSCode's Pluto notebook cells via
# home/pluto.nix. Importing it twice is free; the derivation is identical.
{
  pkgs,
  inputs,
}:
# jetls-nix pins JULIA_DEPOT_PATH to its own store depot so the server never
# touches ~/.julia. That is right for loading JETLS itself and wrong for the
# code it analyses: full analysis asks Pkg whether the target environment is
# instantiated, and Pkg.Types.EnvCache writes a usage log into depot 1 on
# construction. Against a store depot that throws EROFS, JETLS reports
# "Failed to inspect package environment", assumes the environment needs
# instantiating, and -- since instantiating into the store fails too -- falls
# back to analysing the package as a script, which costs the type-sensitive
# half of the server. Measured on a throwaway package:
#
#   JULIA_DEPOT_PATH=<store>/depot  -> EnvCache throws EROFS
#   JULIA_DEPOT_PATH=<writable>     -> manifest_current=true instantiated=true
#
# So prepend the real depot (writable, and where this machine's packages
# actually live) and keep the store depot behind it, which is where JETLS's
# own dependencies and precompile caches resolve from. Package lookup is by
# tree hash, so a stray copy of a JETLS dependency in ~/.julia cannot shadow
# the pinned one.
#
# JULIA_PKG_OFFLINE is dropped in the same patch: offline mode would leave the
# instantiation prompt unable to do the thing it is asking permission for.
# Nothing is downloaded unanswered -- auto_instantiate defaults to "prompt".
#
# JULIA_CPU_TARGET=generic goes too, and that one is the difference between
# "analysing" and "apparently hung". Julia folds the cpu target into the
# *filename* of a precompile cache (`compilecache_path` in base/loading.jl
# crc32s project, image, binary, flags, cpu target and preferences into the
# slug), so a server pinned to "generic" cannot see any cache this machine
# already built and recompiles every dependency of every project it analyses.
# Opening a file in ~/UCT/sandbox (ModelingToolkit, SciMLSensitivity, Zygote,
# Lux, Plots, Pluto) sat at 0% while it rebuilt that tree into a parallel set
# of cache files. Unset, the slug matches the one `julia --project` produces,
# so JETLS loads the caches that are already there.
#
# Nothing is lost at the other end: validation is asymmetric. A cache built
# for "generic" runs anywhere, so JETLS still loads its own store-built
# caches under the default target, while a cache built for this host is
# rejected when "generic" is demanded -- which is why the pinned server could
# not reuse anything. Measured against a scratch depot: `using JETLS`
# succeeds and writes no cache files at all.
let
  # Not inputs.jetls-nix.packages.<system>.jetls any more: that is this same
  # package.nix with an unpatched source, and the patch is what lets JETLS
  # serve Pluto notebooks in VSCode -- see
  # home/nvim/jetls-pluto-notebook.patch for the one-hunk reason, and
  # home/pluto.nix for the client side.
  #
  # jetls-nix's package.nix hardcodes `src` in a let binding, so there is no
  # override point for a patched JETLS. Every source it fetches does go
  # through its `fetchFromGitHub` *argument*, though, and callPackage lets
  # that argument be replaced. The two kinds of fetch are distinguishable:
  # JETLS itself arrives by `tag`, while the vendored [sources] packages
  # (JETLSCore among them, which is the one that holds the notebook module
  # and the copy that actually gets loaded) arrive by `rev` from the same
  # repo. All 18 [sources] entries call it with identical args, so this is
  # one fetch and one applyPatches, reused, each entry then taking its own
  # subdir from the patched tree.
  #
  # julia = pkgs.julia-bin matches what jetls-nix's own flake passes, and
  # its nixpkgs follows ours, so this is byte-for-byte the upstream build
  # plus the patch. applyPatches fails the build rather than skipping, so a
  # jetls-nix bump that moves the hunk is loud.
  upstream = pkgs.callPackage "${inputs.jetls-nix}/package.nix" {
    julia = pkgs.julia-bin;
    fetchFromGitHub = args: let
      fetched = pkgs.fetchFromGitHub args;
    in
      if args ? rev
      then
        pkgs.applyPatches {
          name = "JETLS-pluto-notebook-src";
          src = fetched;
          patches = [./jetls-pluto-notebook.patch];
        }
      else fetched;
  };
in
  pkgs.runCommand "jetls-${upstream.version}-user-depot" {
    inherit (upstream) meta;
    passthru = {inherit upstream;};
  } ''
    mkdir -p $out/bin
    substitute ${upstream}/bin/jetls $out/bin/jetls \
      --replace-fail \
        'export JULIA_DEPOT_PATH=${upstream.environment}/depot' \
        'export JULIA_DEPOT_PATH="''${JULIA_DEPOT_PATH:-$HOME/.julia}:${upstream.environment}/depot"' \
      --replace-fail \
        'export JULIA_PKG_OFFLINE=true' \
        '# JULIA_PKG_OFFLINE intentionally unset; see home/nvim/jetls.nix' \
      --replace-fail \
        'export JULIA_CPU_TARGET=generic' \
        '# JULIA_CPU_TARGET intentionally unset; see home/nvim/jetls.nix'
    chmod +x $out/bin/jetls
  ''
