inputs: self:
let
  homeManagerCfg = userPackages: extraImports: {
    home-manager.useGlobalPkgs = false;
    home-manager.extraSpecialArgs = {
      inherit inputs;
    };
    home-manager.users.dan.imports = [
      #      inputs.nix-index-database.hmModules.nix-index
      ./homeManagerRoles/default.nix
    ]
    ++ extraImports;
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
      };
      modules = [
        ./hosts/${machineHostname}/configuration.nix
        ./nixosRoles/default.nix
      ]
      ++ extraModules
      ++ nixpkgsVersion.lib.optionals (
        (nixpkgsVersion.lib.elem inputs.home-manager-unstable.nixosModules.home-manager extraModules)
        || (nixpkgsVersion.lib.elem inputs.home-manager.nixosModules.home-manager extraModules)
      ) [ (homeManagerCfg false [ ]) ]
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
