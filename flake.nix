{

  description = "My cool flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Sops-nix
    #sops-nix.url = "github:Mic92/sops-nix";

    # Nixvim
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      #      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wazuh-agent = {
      url = "github:paulvictor/wazuh.nix";
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
      ])
      (mkNixos "nixos-testing2" inputs.nixpkgs-unstable [
        inputs.home-manager-unstable.nixosModules.home-manager
      ])
      (mkNixos "technitium-dns" inputs.nixpkgs [
      ])
      (mkNixos "dennis" inputs.nixpkgs [
        inputs.home-manager.nixosModules.home-manager
      ])
      (mkNixos "charlie" inputs.nixpkgs-unstable [
        inputs.home-manager-unstable.nixosModules.home-manager
      ])
      (mkNixos "backupBox" inputs.nixpkgs [
      ])
      (mkNixos "metrics" inputs.nixpkgs [
      ])
      (mkNixos "mac" inputs.nixpkgs [
        inputs.disko.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
      ])
      (mkNixos "edgeware" inputs.nixpkgs [
        inputs.disko.nixosModules.default
      ])
      (mkNixos "frank" inputs.nixpkgs [
        inputs.disko.nixosModules.default
      ])
      #      (mkNixos "generic-vm" inputs.nixpkgs [
      #	inputs.nixos-generators.nixosModules.all-formats
      #      ])
    ];

}
