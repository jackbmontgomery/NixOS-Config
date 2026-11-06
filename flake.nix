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

    obsidian-plugins = {
      url = "github:cjavad/nixpille-obsidian-community-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jetls-nix = {
      url = "github:L3MON4D3/jetls-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
            inputs.obsidian-plugins.overlays.default
            (final: prev: {
              obsidianPlugins =
                prev.obsidianPlugins
                // {
                  vim-motions = inputs.obsidian-plugins.lib.mkPlugin prev {
                    owner = "saberzero1";
                    repo = "motions";
                    version = "1.5.1";
                    hash = "sha256-B04zbE5wyHbHE1/XNfTYs8eT/Pf2u8+nDpzQZKealhc=";
                  };
                };
            })
          ];
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {inherit inputs;};
            sharedModules = [nvf.homeManagerModules.default];
            users.jbm = ./home.nix;
          };
        }
      ];
    };
  };
}
