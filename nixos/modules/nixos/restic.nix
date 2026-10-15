{ config, pkgs, ... }:

{
  # On s'assure que restic est installé
  environment.systemPackages = [ pkgs.restic ];

  # Configuration de la sauvegarde automatique
  services.restic.backups = {
    daily-backup = {
      # Destination de la sauvegarde (le NAS monté)
      repository = "/home/laurent/BacASable/Ordinateur/PCPDL/sauvegarde";
      
      # Fichier contenant le mot de passe (déchiffré par SOPS au vol)
      passwordFile = config.sops.secrets.restic_password.path;
      
      # Ce qu'on veut sauvegarder (tout le dossier personnel)
      paths = [
        "/home/laurent"
      ];
      
      # Ce qu'on exclut
      exclude = [
        "/home/laurent/BacASable" # On ne veut pas sauvegarder le NAS sur lui-même !
        "/home/laurent/Jeux"
        "/home/laurent/Téléchargements"
        "/home/laurent/.cache"
        "/home/laurent/.local/share/Trash"
        "/home/laurent/.local/share/Steam"
      ];

      # Fréquence (tous les jours à 12:00 et 20:00)
      timerConfig = {
        OnCalendar = "12,20:00:00";
        Persistent = true;
      };
      
      # Prune : on garde un certain nombre d'historiques pour ne pas saturer le disque
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];

      # Crée le dépôt s'il n'existe pas encore
      initialize = true;
    };
  };
}
