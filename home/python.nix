{pkgs, ...}: {
  # TY_UV is set in the `mo` launcher (scripts.nix), not session-wide. Opening
  # a notebook with plain `code` therefore gets no type information; `mo` is
  # the way in. Reinstate with `scripts`, not `1`, to keep the integration to
  # PEP 723 files:
  #
  #   home.sessionVariables.TY_UV = "scripts";

  programs.uv = {
    enable = true;

    # unstable: ty's PEP 723 script integration drives uv through
    # `uv workspace metadata --sync`, which does not exist before uv 0.12.3 --
    # stable nixpkgs is on 0.11.21 and ty just prints uv's usage error. With
    # 0.13.0 a sandboxed marimo notebook type-checks against its own inline
    # dependencies. See the TY_UV notes in scripts.nix.
    package = pkgs.unstable.uv;

    # Needs home-manager > release-26.05: these options landed in
    # nix-community/home-manager#9507, merged to master 2026-06-17, after
    # 26.05 branched.
    # https://github.com/nix-community/home-manager/pull/9507
    # python = {
    #   versions = ["3.14"];
    #   default = ["3.14"];
    #   prune = true;
    # };
    #
    # tool = {
    #   packages = [];
    #   prune = true;
    # };
  };
}
