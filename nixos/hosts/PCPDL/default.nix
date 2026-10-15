{ config, pkgs, inputs, ... }:

{
  imports = [
    # 1. Configuration matérielle propre à cette machine
    ./hardware-configuration.nix

    # 2. Importation de tous les modules système communs
    ../../modules/nixos
  ];

  # Nom d'hôte de la machine
  networking.hostName = "PCPDL";

  # Version d'état NixOS
  system.stateVersion = "26.05";
}
