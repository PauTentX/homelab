{ config, pkgs, ... }:

{
  # Autoriser les paquets propriétaires et versions requises
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-40.10.5"
      "electron-40.10.2"
      "ventoy-1.1.17"
    ];
  };

  nixpkgs.overlays = [
    # Fix pour sops-nix qui demande une vieille version de Go supprimée de Unstable
    (final: prev: {
      buildGo125Module = prev.buildGoModule;
    })
  ];

  # Paramètres Nix et fonctionnalités expérimentales
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    warn-dirty = false;
    # Maximiser le parallélisme sur PCPDL
    max-jobs = "auto";
    cores = 0;
  };

  # Nettoyage automatique hebdomadaire (Garbage Collection)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # 🚀 nix-ld : Exécution transparente de binaires génériques Linux (Node, Electron, etc.)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Bibliothèques fondamentales pour Electron, Chrome & Node natif
      glib
      gtk3
      nss
      nspr
      atk
      at-spi2-atk
      at-spi2-core
      cups
      dbus
      pango
      cairo
      gdk-pixbuf
      libdrm
      mesa
      libgbm
      expat
      alsa-lib
      systemd
      libxkbcommon
      libx11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
      libxkbfile
      libXcursor
      libXi
      libXrender
      libXtst
      libXScrnSaver
    ];
  };
}
