{ config, pkgs, ... }:

{
  # Bluetooth (Géré nativement par KDE Plasma via Bluedevil / BlueZ)
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Réseau (Utilisation de wpa_supplicant par défaut pour la stabilité)
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false; # Désactive l'économie d'énergie Wi-Fi pour éviter les déconnexions intempestives
  };

  # Gestion de l'énergie et processeur Intel (Laptop)
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Basculement automatique : Performance sur secteur, Eco sur batterie
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
  '';

  # 🗜️ Optimisation Btrfs automatique
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" "/home" "/nix" ];
  };

  # Maintenance SSD NVMe (TRIM)
  services.fstrim.enable = true;

  # 🚀 Anti-Freeze : Swap compressé en RAM (ZRAM)
  # Absolument vital quand on utilise des VMs ou des compilations Nix lourdes.
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50; # Permet jusqu'à 16Go de swap compressé


  # Lecteur d'empreinte digitale (Authentification et Sudo)
  services.fprintd.enable = true;

  # Serveur SSH
  services.openssh.enable = true;

  # Localisation & Clavier
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";
  console.keyMap = "fr";
}
