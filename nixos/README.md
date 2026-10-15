# ❄️ Configurations NixOS & Flakes du Homelab

Bienvenue sur le dépôt déclaratif de configuration **NixOS** du Homelab. Ce projet configure plusieurs machines via des **Nix Flakes**, combinant une gestion modulaire du système et des environnements utilisateur avec **Home Manager**.

---

## 🏛️ Architecture & Machines

Le dépôt est articulé autour de deux hôtes principaux :

| Hôte | Type | Rôle & Composants clés |
|---|---|---|
| **`PCPDL`** | Laptop de travail | Bureau KDE Plasma 6 Wayland, Stylix (thématisation globale), Home Manager, sops-nix, Zen Browser, suite SysAdmin & DevOps. |
| **`EVA-003`** | Serveur IA Bare-Metal | Headless (sans interface graphique), partitionnement déclaratif **Disko** (RAID0 NVMe + XFS), accélération GPU NVIDIA (CUDA), Ollama local, Odysseus workspace. |

---

## 📂 Arborescence du Dépôt

```text
.
├── flake.nix                # Point d'entrée Flake définissant inputs et configurations hôtes
├── flake.lock               # Verrouillage exact des révisions nixpkgs et inputs tiers
├── hosts/                   # Configurations spécifiques à chaque machine
│   ├── PCPDL/               # Laptop principal
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── EVA-003/             # Serveur IA headless
│       ├── default.nix
│       └── hardware-configuration.nix
├── modules/                 # Modules NixOS et Home Manager réutilisables
│   ├── nixos/               # Modules système (boot, audio, nvidia, samba, sops, etc.)
│   └── home/                # Modules Home Manager (terminal, git, plasma, vscode, hermes)
├── secrets/                 # Documentation et structure sops-nix (aucun secret en clair)
│   └── README.md
├── Wallpapers/              # Collection de fonds d'écran intégrés
├── .sops.yaml               # Règles de chiffrement SOPS / age d'exemple
├── LICENSE                  # Licence MIT
└── README.md                # Documentation principale
```

---

## ⚙️ Concepts Clés

### 1. Flakes (`flake.nix`)
Le fichier `flake.nix` déclare de manière reproductible l'ensemble des dépendances (`nixpkgs`, `home-manager`, `disko`, `stylix`, `sops-nix`). Les versions exactes sont figées dans `flake.lock`.

### 2. Disko (Partitionnement déclaratif)
Sur `EVA-003`, le module `modules/nixos/nvidia-ollama.nix` et `disko` définissent le stockage NVMe RAID0 avec système de fichiers XFS pour le cache et les modèles d'IA sans intervention manuelle.

### 3. Gestion des Secrets (`sops-nix`)
Les secrets (mots de passe, tokens) sont gérés avec **sops-nix** et chiffrés avec des clés `age` (ou clés d'hôtes SSH).
- Le modèle de configuration se trouve dans `.sops.yaml`.
- Aucun fichier de secrets déchiffré ni clé privée n'est présent dans ce dépôt public.
- Pour initialiser vos secrets locaux :
  ```bash
  sops secrets/secrets.yaml
  ```

---

## 🚀 Déploiement & Utilisation

### Prérequis
- NixOS installé ou environnement Nix avec support des **Flakes** activé :
  ```nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  ```

### Vérification de la configuration
Pour vérifier l'évaluation du Flake :
```bash
nix flake check
```

### Déploiement local sur une machine
Pour appliquer la configuration sur la machine courante :

```bash
# Pour le laptop PCPDL
sudo nixos-rebuild switch --flake .#PCPDL

# Pour le serveur IA EVA-003
sudo nixos-rebuild switch --flake .#EVA-003
```

### Test avant application permanente
Pour tester une configuration sans l'ajouter au menu de boot :
```bash
sudo nixos-rebuild test --flake .#PCPDL
```

---

## 🔒 Sécurité et Assainissement

Ce dépôt a été entièrement assaini avant publication :
- **Secrets supprimés** : Aucun mot de passe, token API ou clé privée n'est inclus.
- **Identifiants matériels** : Les UUID et numéros de série de disques dans `hardware-configuration.nix` sont remplacés par des placeholders (`00000000-...`). Vous devez générer votre configuration matérielle avec `nixos-generate-config`.
- **Informations privées** : Les adresses e-mail et noms de domaine réels ont été masqués par des exemples (`example.com`).

---

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier [LICENSE](./LICENSE) pour plus de détails.
