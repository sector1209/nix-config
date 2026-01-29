inputs: self:
let
  homeManagerCfg = userPackages: extraImports: nixpkgsVersion: extraModules: machineHostname: {
    home-manager.useGlobalPkgs = false;
    home-manager.extraSpecialArgs = {
      inherit inputs;
    };
    home-manager.users.dan.imports = [
      ./homeManagerRoles/default.nix
    ]
    ++ extraImports
    ++ nixpkgsVersion.lib.optionals (
      (nixpkgsVersion.lib.elem inputs.home-manager-unstable.nixosModules.home-manager extraModules)
      || (nixpkgsVersion.lib.elem inputs.home-manager.nixosModules.home-manager extraModules)
    ) [ ./hosts/${machineHostname}/home-manager-configuration.nix ];
    home-manager.backupFileExtension = "bak";
    home-manager.useUserPackages = userPackages;
  };
  overlays = [
    {
      nixpkgs.overlays = [
        (final: prev: {
          unfree = import inputs.nixpkgs {
            system = prev.system;
            config.allowUnfree = true;
          };
          unstable = import inputs.nixpkgs-unstable { system = prev.system; } // {
            unfree = import inputs.nixpkgs-unstable {
              system = prev.system;
              config.allowUnfree = true;
            };
          };
        })
        (import ./packages)
        (self: super: {
          wazuh-agent = inputs.wazuh-agent.packages.x86_64-linux.wazuh-agent;
        })
      ];
    }
  ];
in
{

  mkNixos = machineHostname: nixpkgsVersion: extraModules: rec {
    nixosConfigurations.${machineHostname} = nixpkgsVersion.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs self;
        secrets = import inputs.nix-secrets;
      };
      modules = [
        ./hosts/${machineHostname}/configuration.nix
        ./nixosRoles/default.nix
      ]
      ++ extraModules
      ++ nixpkgsVersion.lib.optionals (
        (nixpkgsVersion.lib.elem inputs.home-manager-unstable.nixosModules.home-manager extraModules)
        || (nixpkgsVersion.lib.elem inputs.home-manager.nixosModules.home-manager extraModules)
      ) [ (homeManagerCfg false [ ] nixpkgsVersion extraModules machineHostname) ]
      ++
        nixpkgsVersion.lib.optionals
          (nixpkgsVersion.lib.elem inputs.disko.nixosModules.default extraModules)
          [ (import ./hosts/${machineHostname}/disko.nix) ]
      ++ overlays;
    };
  };
  mkMerge = inputs.nixpkgs.lib.lists.foldl' (
    a: b: inputs.nixpkgs.lib.attrsets.recursiveUpdate a b
  ) { };
}
