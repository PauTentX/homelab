{
  description = "Configuration NixOS de Laurent (KDE Plasma 6 + Wayland + Serveur IA)";

  # 1. Les sources (Inputs)
  # C'est ici qu'on définit d'où viennent nos paquets.
  inputs = {
    # On utilise la branche UNSTABLE pour avoir les derniers paquets (Hyprland, Wayland, etc.)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Disko pour la gestion déclarative des disques (NOUVEAU)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix : Le gestionnaire de thème universel automatique pour tout NixOS
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma-Manager : Gestion déclarative complète de KDE Plasma 6 via Home Manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Le Flake communautaire officiel de Zen Browser (mise à jour très fréquente)
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    
    # Le Flake communautaire pour Antigravity IDE !
    antigravity = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hermes Agent : app Desktop officielle (client du backend LXC 105).
    # Pas de nixpkgs.follows : le flake épingle son propre nixpkgs/uv2nix (Tier 2, best-effort).
    hermes-agent.url = "github:NousResearch/hermes-agent";

    # Sops-nix : Gestion des secrets chiffrés
    sops-nix.url = "github:Mic92/sops-nix";

    # Home Manager : L'outil magique pour gérer tes configurations utilisateur (dotfiles)
    home-manager = {
      # On s'assure d'utiliser la branche de Home Manager correspondante à notre version NixOS (Unstable/Master)
      url = "github:nix-community/home-manager";
      # On dit à Home Manager d'utiliser les mêmes paquets que le système global
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
  };

  # 2. Les résultats (Outputs)
  # C'est ici qu'on assemble les pièces du puzzle pour construire le système.
  outputs = { self, nixpkgs, home-manager, stylix, sops-nix, disko, ... }@inputs: {
    
    nixosConfigurations = {
      # "PCPDL" doit correspondre exactement au networking.hostName
      PCPDL = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; # On passe les inputs aux autres fichiers
        
        modules = [
          # 1. Configuration de la machine (matériel + modules système)
          ./hosts/PCPDL
          stylix.nixosModules.stylix
          sops-nix.nixosModules.sops
          
          # 2. Configuration utilisateur intégrée via Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            
            # 3. Modules utilisateur de Laurent
            home-manager.users.laurent = {
              imports = [
                inputs.plasma-manager.homeModules.plasma-manager
                ./modules/home
              ];
            };
          }
        ];
      };

      # Le nouveau Serveur IA (Headless & Bare Metal)
      EVA-003 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        
        modules = [
          disko.nixosModules.disko
          ./hosts/EVA-003/hardware-configuration.nix
          ./hosts/EVA-003/default.nix
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.laurent = { pkgs, ... }: {
              imports = [
                # On importe VOS modules de terminal pour garder votre confort SSH
                ./modules/home/terminal/default.nix 
                ./modules/home/git.nix
              ];
              home.stateVersion = "24.05";
            };
          }
        ];
      };
    };
  };
}
