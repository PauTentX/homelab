{ config, pkgs, ... }:

{
  # Point de montage Samba / CIFS avec automount système sécurisé
  # - Ne bloque jamais le démarrage hors réseau (noauto, nofail)
  # - Se démonte après 60s d'inactivité (idle-timeout)
  # - Timeout de 2s max en cas d'absence du réseau
  fileSystems."/mnt/BacASable" = {
    device = "//nas.local/BacASable";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=2s"
      "x-systemd.mount-timeout=2s"
      "uid=1000"
      "gid=100"
      "credentials=/etc/nixos/smb-secrets"
      "nofail"
      "_netdev"
      "iocharset=utf8"
      "file_mode=0770"
      "dir_mode=0770"
    ];
  };

  # Services réseau pour Samba et découverte automatique (WSDD + Avahi)
  services.gvfs.enable = true;
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
