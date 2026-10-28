{
  programs.uv = {
    enable = true;

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
