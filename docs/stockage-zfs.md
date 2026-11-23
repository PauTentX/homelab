# Stockage et sauvegardes

Relevé du 23/11/2026.

## TrueNAS SCALE (EVA-001) : pool `BacASable`

| Élément | Valeur |
| :--- | :--- |
| Données | Miroir de 2 disques Seagate IronWolf 8 To (`mirror-0`) |
| Cache de lecture | L2ARC sur un NVMe 1 To |
| Système | `boot-pool` sur un NVMe 500 Go, séparé |
| Capacité | 7,27 Tio, dont 5,05 Tio utilisés (69 %) et 2,21 Tio libres |
| État | `ONLINE`, aucune erreur de lecture, d'écriture ou de somme de contrôle |

**Miroir.** Chaque bloc est écrit sur les deux disques. Le pool survit à la perte de l'un d'eux.
ZFS stocke une somme de contrôle par bloc : si une copie est corrompue, il le voit à la lecture
et la répare à partir de l'autre.

**L2ARC.** L'ARC est le cache en RAM de ZFS. Le L2ARC prolonge ce cache sur le NVMe pour les
lectures répétées. Il ne contient aucune donnée unique : si le NVMe meurt, seul le cache est perdu.

### Datasets principaux

| Dataset | Utilisé | Contenu |
| :--- | ---: | :--- |
| `BacASable/BacASable` | 4,96 Tio | Médias et données partagées (partage SMB) |
| `BacASable/ix-apps` | 84 Gio | Applications TrueNAS, dont la supervision |
| `BacASable/User` | 65 Gio | Données personnelles |
| `BacASable/backups` | 3,9 Gio | Sauvegardes Home Assistant (partage SMB dédié) |
| `BacASable/hermes-backups` | 1,5 Gio | Sauvegardes de l'agent Hermes |

### Instantanés et scrub

| Tâche | Fréquence | Rétention |
| :--- | :--- | :--- |
| Snapshot `BacASable/BacASable` | Tous les jours à 03:00 | 7 jours |
| Snapshot `BacASable/BacASable` | Le dimanche à 03:30 | 4 semaines |
| Snapshot `BacASable/User` (récursif) | Tous les jours à 03:20 | 14 jours |
| Scrub du pool | Le dimanche, si le précédent date de plus de 35 jours | — |

Un snapshot ZFS est quasi instantané : il fige la liste des blocs sans rien copier, puis grossit
au fil des modifications. Il protège contre une suppression ou un chiffrement par erreur, pas
contre la perte du pool, puisqu'il vit sur les mêmes disques.

Le scrub relit tous les blocs et vérifie leurs sommes de contrôle. Dernier passage le
1er novembre : 9 h 30, 0 octet réparé.

## Hyperviseur (EVA-002)

| Disque | Usage |
| :--- | :--- |
| NVMe 500 Go | Groupe LVM `pve` : système (96 Go), swap (8 Go), pool thin `data` (338 Go) pour les disques des invités |
| SSD SATA 2 To | Groupe LVM `Backshot-Roulette` : volume `backup-lv` de 500 Go monté sur `/mnt/backup2to` |

Le pool **thin** alloue l'espace au fil de l'écriture : un disque virtuel de 32 Go qui contient
5 Go de données n'en occupe que 5 sur le NVMe.

## Sauvegardes vzdump

| Paramètre | Valeur |
| :--- | :--- |
| Planification | Le dimanche à 01:00 |
| Mode | `snapshot` : l'invité continue de tourner pendant la sauvegarde |
| Compression | zstd |
| Rétention | 2 versions (`keep-last=2`) |
| Destination | `/mnt/backup2to`, 268 Go utilisés sur 492 |
| Invités | Liste fixe de 35 vmid |

L'exporter [homelab_smart_probe.py](../scripts/homelab_smart_probe.py) publie la date et le
statut du dernier job, et l'état du système de fichiers de destination. Les alertes
`BackupJobEchoue`, `BackupStale` et `BackupFsReadonly` s'appuient dessus.

## Limites

- **Pas de copie hors site.** Les sauvegardes vzdump sont sur la même machine que les invités, et
  TrueNAS n'a aucune tâche de réplication, de synchronisation cloud ou de rsync.
- **Liste d'invités figée.** Le job vise des vmid précis. Quatre LXC démarrés n'y sont pas :
  107, 141, 143 et 160. Choisir « tous les invités » avec des exclusions éviterait l'oubli.
- 2 versions seulement : une corruption remarquée après deux semaines n'a plus de copie saine.
- Aucun test de restauration documenté.
