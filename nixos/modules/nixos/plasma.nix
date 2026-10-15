{ config, pkgs, ... }:

{
  # Environnement de bureau KDE Plasma 6 (Wayland)
  services.desktopManager.plasma6 = {
    enable = true;
  };

  # Intégration et partage KDE Connect (ouvre automatiquement les ports nécessaires)
  programs.kdeconnect.enable = true;

  # Agent de sécurité et authentification Polkit
  security.polkit.enable = true;
}
