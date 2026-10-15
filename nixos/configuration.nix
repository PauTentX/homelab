{ config, pkgs, inputs, ... }:

{
  # 1. Imports de la configuration matérielle
  imports =
    [
      ./hardware-configuration.nix
    ];

  # 2. Démarrage du système
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 3. Réseau et Bluetooth
  networking.hostName = "PCPDL";
  networking.networkmanager.enable = true;
  
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Serveur SSH pour prendre le contrôle depuis un autre PC
  services.openssh.enable = true;

  # 4. Localisation
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";
  console.keyMap = "fr";

  # 5. Stylix : Le gestionnaire de thème universel automatique
  stylix = {
    enable = true;

    # Fond d'écran officiel Catppuccin (vous pouvez le remplacer par le chemin vers n'importe quelle image locale)
    image = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/landscapes/shaded_landscape.png";
      hash = "sha256-EZmkN1HxI00/uS7PYU+/NN4sBzNNP901WJEET1G92to=";
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";

    cursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sizes = {
        applications = 11;
        terminal = 13;
        desktop = 10;
        popups = 10;
      };
    };
  };


  # 6. Window Manager : HYPRLAND !
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = false;
  };

  # 7. Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # 8. Gestion de l'énergie et matériel (Optimisations Laptop Intel & SSD)
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  services.fstrim.enable = true;

  # 9. Sécurité et agent Polkit (Popups d'autorisation d'administration)
  security.polkit.enable = true;

  # --- Synchronisation en arrière-plan ---
  services.syncthing = {
    enable = true;
    user = "laurent";
    dataDir = "/home/laurent/";    # Dossier par défaut
    configDir = "/home/laurent/.config/syncthing";
  };

  # 10. Utilisateur et paquets
  users.users.laurent = {
    isNormalUser = true;
    description = "Laurent";
    extraGroups = [ "networkmanager" "wheel" ];

    packages = with pkgs; [
      # Navigateurs & Bureautique
      firefox
      vlc
      fastfetch
      obs-studio
      zed-editor
      inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
      inputs.antigravity.packages."${pkgs.stdenv.hostPlatform.system}".google-antigravity-no-fhs
      inputs.antigravity.packages."${pkgs.stdenv.hostPlatform.system}".google-antigravity-ide-no-fhs

      # Outils Hyprland & Wayland
      wofi
      swaynotificationcenter
      hyprpaper
      hyprlock
      hypridle
      grim           # Capture d'écran
      slurp          # Sélection de zone pour capture
      wl-clipboard   # Gestionnaire de presse-papier Wayland
      brightnessctl  # Contrôle de la luminosité écran
      jq             # Traitement JSON pour les coordonnées de fenêtres Hyprland
      libnotify      # Envoi de notifications système (notify-send)

      # Agent Polkit (authentification graphique)
      kdePackages.polkit-kde-agent-1

      # Panneaux de configuration (GUI)
      nwg-displays          # Config écran graphique
      pavucontrol           # Panneau de contrôle son
      networkmanagerapplet  # Outil Wifi dans la barre

      # Explorateur de fichiers & Synchronisation
      kdePackages.dolphin
      syncthing
    ];
  
    shell = pkgs.fish;};

  # 11. Système global & Optimisations Nix
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
nix.settings = {
        substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8Pwtkuf0="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3FS="
    ];


  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  environment.systemPackages = with pkgs; [
    btop
    eza
    bat
    ripgrep
    fd
    nmap
    mtr
    bind.dnsutils
    iperf3

    vim
    wget
    curl

    kdePackages.qtdeclarative     # Nécessaire pour le moteur graphique QML de SDDM
    kdePackages.qtsvg             # Nécessaire pour les icônes SVG de SDDM
    kdePackages.qt5compat         # Compatibilité QtQuick pour le thème SDDM
    nixfmt                       # Formateur de code officiel pour Nix
    nixd                         # Serveur de langage (LSP) pour Nix
  ];

  # Polices d'icônes (Nerd Fonts) indispensables pour afficher les icônes Waybar
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  system.stateVersion = "26.05";
}
