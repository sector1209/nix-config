{

  description = "My cool flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Sops-nix
    #sops-nix.url = "github:Mic92/sops-nix";

    # Nixvim
    nixvim-unstable = {
      url = "github:nix-community/nixvim";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };

    # Disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation = {
      url = "github:nix-community/preservation";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets.url = "git+ssh://git@github.com-nix-secrets/sector1209/nix-secrets.git";

  };

  outputs =
    {
      self,
      ...
    }@inputs:
    let

      helpers = import ./flakeHelpers.nix inputs self;
      inherit (helpers) mkMerge mkNixos;

    in

    mkMerge [
      (mkNixos "nixos-testing" inputs.nixpkgs-unstable [
        inputs.home-manager-unstable.nixosModules.home-manager
        inputs.nixvim-unstable.nixosModules.nixvim
      ])
      (mkNixos "nixos-testing2" inputs.nixpkgs-unstable [
        inputs.home-manager-unstable.nixosModules.home-manager
        inputs.nixvim-unstable.nixosModules.nixvim
      ])
      (mkNixos "technitium-dns" inputs.nixpkgs [
        inputs.nixvim.nixosModules.nixvim
      ])
      (mkNixos "dennis" inputs.nixpkgs [
        inputs.home-manager.nixosModules.home-manager
        inputs.nixvim.nixosModules.nixvim
      ])
      (mkNixos "charlie" inputs.nixpkgs-unstable [
        inputs.home-manager-unstable.nixosModules.home-manager
        inputs.nixvim-unstable.nixosModules.nixvim
      ])
      (mkNixos "backupBox" inputs.nixpkgs [
        inputs.nixvim.nixosModules.nixvim
      ])
      (mkNixos "metrics" inputs.nixpkgs-unstable [
        inputs.nixvim-unstable.nixosModules.nixvim
      ])
      (mkNixos "mac" inputs.nixpkgs [
        inputs.nixvim.nixosModules.nixvim
        inputs.disko.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
      ])
      (mkNixos "edgeware" inputs.nixpkgs [
        inputs.nixvim.nixosModules.nixvim
        inputs.disko.nixosModules.default
      ])
      (mkNixos "frank" inputs.nixpkgs [
        inputs.nixvim.nixosModules.nixvim
        inputs.disko.nixosModules.default
      ])
      (mkNixos "impermanence-testing" inputs.nixpkgs [
        inputs.nixvim.nixosModules.nixvim
        inputs.disko.nixosModules.default
      ])
      #      (mkNixos "generic-vm" inputs.nixpkgs [
      #	inputs.nixos-generators.nixosModules.all-formats
      #      ])
    ];

}
