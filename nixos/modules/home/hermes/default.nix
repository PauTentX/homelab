{ config, pkgs, lib, inputs, ... }:

let
  # Client léger : ouvre le CLI Hermes DANS le conteneur du Homelab (LXC 105).
  # Une seule base de sessions/mémoire/skills, aucune clé API sur le laptop.
  hchat = pkgs.writeShellScriptBin "hchat" ''
    exec ${pkgs.openssh}/bin/ssh -t root@192.168.1.100 \
      "docker exec -it hermes hermes ''${@:-chat}"
  '';
in
{
  home.packages = [
    hchat
    # App Desktop (Electron), client du dashboard Hermes du LXC 105.
    # Premier lancement : Settings > Gateway > Remote > http://192.168.1.100:8642
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
  ];

  home.shellAliases = {
    h = "hchat";
    hermes = "hchat";
  };
}
