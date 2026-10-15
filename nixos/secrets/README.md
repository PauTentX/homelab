# Gestion des secrets avec sops-nix

Ce dossier est destiné à accueillir les secrets chiffrés avec [sops-nix](https://github.com/Mic92/sops-nix) et `age`.

## Fonctionnement

1. **Aucun secret réel n'est commité en clair dans ce dépôt public.**
2. Le fichier chiffré attendu par la configuration NixOS (`modules/nixos/sops.nix`) est `secrets/secrets.yaml`.
3. Pour initialiser ou éditer votre fichier `secrets.yaml` local :
   ```bash
   # Configurer votre clé privée age ou clé SSH dans ~/.config/sops/age/keys.txt
   sops secrets/secrets.yaml
   ```

## Structure attendue dans `secrets/secrets.yaml`
```yaml
restic_password: "VOTRE_MOT_DE_PASSE_RESTIC"
nextcloud_password: "VOTRE_MOT_DE_PASSE_NEXTCLOUD"
```

## Configuration `.sops.yaml`
Un modèle `.sops.yaml` est fourni à la racine du dépôt pour associer vos clés publiques `age` aux règles de chiffrement.
