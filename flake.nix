{
  description = "NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # JETLS is not in nixpkgs, and upstream only ships an imperative install
    # (`Pkg.Apps.add` into ~/.julia/bin). This flake resolves it through
    # julia.withPackages instead, so sources, project, depot and precompile
    # caches all live in the store and ~/.julia is left alone. It uses
    # import-from-derivation, so evaluating this config can trigger Julia
    # builds mid-eval. Bumping the JETLS release means bumping this input.
    jetls-nix = {
      url = "github:L3MON4D3/jetls-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #
    # Live again: home/nvim/languages.nix consumes it for the inferred-type
    # hover that neither fatou nor LanguageServer.jl can produce. The
    # import-from-derivation cost noted above is real and is being
    # paid deliberately -- `nix flake check` and plain evaluation can now
    # trigger a Julia build.

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        home-manager.follows = "home-manager";
      };
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    stylix,
    nvf,
    zen-browser,
    ...
  }: {
    nixosConfigurations.thinkpad = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/thinkpad/default.nix
        stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [
            (final: prev: {
              unstable = import inputs.nixpkgs-unstable {
                inherit (prev.stdenv.hostPlatform) system;
                inherit (prev.config) allowUnfree;
              };
            })
          ];
        }
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.sharedModules = [nvf.homeManagerModules.default];
          home-manager.users.jbm = ./home.nix;
        }
      ];
    };
  };
}
