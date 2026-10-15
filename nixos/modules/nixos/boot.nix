{ config, pkgs, ... }:

{
  # Gestionnaire de démarrage moderne UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10; # Évite d'encombrer l'ESP /boot
  boot.loader.efi.canTouchEfiVariables = true;
}
