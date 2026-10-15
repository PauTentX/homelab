# Contribuer au Homelab

Merci pour votre intérêt pour ce projet de Homelab !

## Bonnes Pratiques & Règles de Contribution

1. **Assainissement Strict des Secrets (Security First)** :
   - Ne **JAMAIS** commiter de clés privées SSH, tokens API, mots de passe, webhooks Discord, adresses MAC réelles ou domaines sensibles.
   - Toujours utiliser des fichiers `.env.example` et des balises `<REDACTED>` pour documenter les configurations.

2. **Conventions de Commits** :
   - Les commits suivent la convention [Conventional Commits](https://www.conventionalcommits.org/) en français :
     - `feat:` Nouvelle stack, nouveau conteneur ou script
     - `fix:` Correction d'un bug ou ajustement de configuration
     - `docs:` Amélioration de la documentation ou des schémas
     - `refactor:` Restructuration sans changement fonctionnel
     - `ci:` Mise à jour des workflows d'automatisation

3. **Validation & Tests** :
   - Vérifier la validité des fichiers YAML (`docker compose config`) avant de proposer une modification.
   - S'assurer que le scan de secrets ne remonte aucune alerte.
