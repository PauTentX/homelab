{ config, pkgs, ... }:

{
  sops = {
    # On précise où se trouve le fichier chiffré
    defaultSopsFile = ../../secrets/secrets.yaml;
    
    # Format YAML
    defaultSopsFormat = "yaml";

    # La clé SSH de l'hôte est utilisée automatiquement par sops-nix pour déchiffrer
    # sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; (défaut)

    # On demande à sops de créer ce fichier déchiffré dans /run/secrets/restic_password
    secrets.restic_password = {};

    # Mot de passe Nextcloud pour la synchronisation du calendrier (lu par vdirsyncer)
    secrets.nextcloud_password = {
      owner = "laurent";
    };
  };
}
