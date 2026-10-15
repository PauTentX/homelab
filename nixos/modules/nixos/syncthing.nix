{ config, pkgs, ... }:

{
  # Service de synchronisation d'arrière-plan Syncthing
  services.syncthing = {
    enable = true;
    user = "laurent";
    dataDir = "/home/laurent/";
    configDir = "/home/laurent/.config/syncthing";
  };
}
