{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/boot.nix
    ../../modules/nixos/hardware.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/nix.nix
    # Le module d'Intelligence Artificielle Natif (Ollama + Disko Mdadm XFS)
    ../../modules/nixos/nvidia-ollama.nix
    ../../modules/nixos/virtualisation.nix
    ../../modules/nixos/odysseus.nix
  ];

  networking.hostName = "EVA-003";
  networking.networkmanager.enable = true;

  # Activation du serveur SSH (Crucial pour l'administration headless)
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # À passer à "no" plus tard
    };
  };

  # Forcer le mode "Terminal pur" (Sans interface graphique)
  systemd.targets.graphical.enable = false;
  systemd.targets.multi-user.enable = true;

  system.stateVersion = "24.05";
}
