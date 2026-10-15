# Exemples de configurations LXC Proxmox VE

Ce répertoire contient une sélection de **3 configurations de référence commentées** issues du cluster Proxmox VE du homelab.

Afin de préserver la sécurité de l'infrastructure et conformément aux bonnes pratiques d'assainissement de code, **l'inventaire complet des conteneurs LXC n'est pas publié publiquement**. Il est archivé et versionné dans un dépôt privé interne dédié à la sauvegarde et à la reconstruction d'urgence.

## Modèles représentatifs documentés

1. **`132-gitea.conf`** : Conteneur non privilégié (`unprivileged: 1`) pour un service applicatif isolé (Forge logicielle Git / CI/CD) avec permissions réseau et sécurisation par namespaces.
2. **`110-npmplus.conf`** : Reverse proxy frontal sous Alpine Linux (`unprivileged: 1`), optimisé pour la terminaison TLS et la redirection de trafic.
3. **`105-dockge.conf`** : Hôte Docker imbriqué (`features: nesting=1`) avec point de montage distant (`mp0`) et passthrough matériel contrôlé (périphériques série/USB).

Chaque fichier contient des commentaires détaillés en en-tête expliquant la fonction de chaque directive Proxmox VE (`cores`, `memory`, `rootfs`, `net0`, `features`, `unprivileged`).
