# Stacks Docker Homelab

Ce dossier contient l'ensemble des définitions de déploiement Docker Compose (`compose.yaml`) ainsi que les modèles de configuration d'environnement associés (`.env.example`) pour les stacks déployées sur les hôtes **LXC 105 Dockge (Proxmox)** et **TrueNAS SCALE**.

Toutes les configurations sont strictement assainies : aucun secret, token, mot de passe ou webhook Discord n'est versionné en clair.

---

## 📋 Inventaire des Stacks

| Stack | Service(s) | Hôte / Environnement | Port(s) | Rôle & Description |
| :--- | :--- | :--- | :--- | :--- |
| **calibre-web-automated** | `calibre-web-automated` | LXC 105 (Dockge) | `8083` | Serveur Calibre-Web avec traitement automatisé de livres numériques et interface de lecture. |
| **calibre-web-automated-book-downloader** | `calibre-web-automated-book-downloader` | LXC 105 (Dockge) | `8084` | Service compagnon de téléchargement automatique d'ebooks pour Calibre-Web. |
| **configarr** | `configarr` | LXC 105 (Dockge) | - | Synchronisation et automatisation de configuration TRaSH Guides pour Sonarr / Radarr. |
| **dockge** | `dockge` | LXC 105 (Dockge) | `5001` | Gestionnaire d'infrastructure Docker et interface WebUI pour orchestrer les stacks Compose. |
| **dozzle** | `dozzle` | LXC 105 (Dockge) | `8080` | Visualiseur léger de logs en temps réel pour l'ensemble des conteneurs Docker de l'hôte. |
| **flaresolverr** | `flaresolverr`, `byparr` | LXC 105 (Dockge) | `9696`, `8191` | Proxy de contournement Cloudflare anti-bot pour Prowlarr et les indexeurs Torznab. |
| **gitea-runner** | `gitea-runner` | LXC 105 (Dockge) | - | Runner d'intégration continue Act Runner connecté à l'instance Gitea locale. |
| **hermes-agent** | `hermes-agent`, `aiclient2api` | LXC 105 (Dockge) | `8642-8644`, `3000`, `8086` | Agent autonome IA Hermes orchestré avec son proxy d'API multi-protocole AIClient2API. |
| **immich** | `immich-server`, `immich-machine-learning`, `redis`, `database` | LXC 105 (Dockge) | `2283` | Solution complète d'auto-hébergement de photos/vidéos avec ML et Postgres vectoriel. |
| **n8n** | `n8n` | LXC 105 (Dockge) | `5678` | Plateforme d'automatisation de workflows no-code/low-code interconnectant les services du Homelab. |
| **nadeko** | `nadeko` | LXC 105 (Dockge) | - | Bot communautaire Discord NadekoBot v6 multi-usages. |
| **truenas-monitoring** | `prometheus`, `grafana`, `alertmanager`, `node-exporter`, `blackbox-exporter`, `freebox-exporter`, `smart-exporter`, `nut-exporter` | TrueNAS SCALE | `3030`, `9090`, `9093`, `9105`, `9199` | Stack de supervision complète du Homelab (métriques matérielles, réseau, onduleur UPS et alerting). |
| **umami** | `umami`, `umami-db` | LXC 105 (Dockge) | `3005` | Analytics web respectueux de la vie privée couplé à une base de données PostgreSQL dédiée. |
| **webhookdiscord** | `discord-relay` | LXC 105 (Dockge) | - | Bot Discord passerelle relayant les commandes du serveur vers les webhooks n8n. |

---

## 🔒 Gestion des Secrets & Assainissement

Chaque stack contient :
- `compose.yaml` : La définition déclarative du ou des conteneurs Docker avec variables externalisées (`${VARIABLE}`).
- `.env.example` : Le fichier d'exemple décrivant les variables nécessaires initialisées à `change_me`.

### Déploiement d'une stack
1. Copier le fichier `.env.example` en `.env` :
   ```bash
   cp .env.example .env
   ```
2. Éditer le fichier `.env` avec les valeurs réelles et sécurisées.
3. Lancer la stack via Dockge ou en ligne de commande :
   ```bash
   docker compose up -d
   ```
