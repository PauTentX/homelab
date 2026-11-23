# Supervision

Relevé du 23/11/2026. Les fichiers de [monitoring/](../monitoring) sont ceux chargés en
production.

## Où ça tourne, et pourquoi

Prometheus, Alertmanager, Grafana, Blackbox et les exporters réseau tournent sur TrueNAS (stack
[truenas-monitoring](../stacks/truenas-monitoring/compose.yaml)), pas sur l'hyperviseur. Si
EVA-002 tombe, la supervision reste debout et peut le signaler.

| Composant | Version | Réglage |
| :--- | :--- | :--- |
| Prometheus | 3.15.0 | Collecte toutes les 15 s, rétention 30 jours |
| Alertmanager | 0.34.1 | Envoi vers Discord |
| Grafana | 13.2.2 | Tableau réseau versionné : [network_dashboard.json](../monitoring/network_dashboard.json) |
| Blackbox exporter | 0.28.0 | Sondes ICMP et HTTP |

## Cibles

29 cibles actives, toutes `up` au moment du relevé.

| Job | Source |
| :--- | :--- |
| `proxmox-ve` | [proxmox_exporter.py](../scripts/proxmox_exporter.py) sur EVA-002 (:9221) : état, CPU et RAM des LXC et VM |
| `smart-proxmox` | [homelab_smart_probe.py](../scripts/homelab_smart_probe.py) sur EVA-002 (:9188) : santé du NVMe, sauvegardes vzdump |
| `node-exporter-proxmox`, `node-exporter-truenas` | Métriques système des deux hôtes |
| `zfs-truenas`, `smart-homelab` | État du pool et des disques du NAS |
| `nut-ups` | Onduleur, via NUT |
| `freebox-delta` | Lien WAN de la Freebox |
| `blackbox-network` (10), `blackbox-http` (4) | Ping des équipements, disponibilité et certificat des sites |
| `exportarr-*` (4), `qbittorrent` | Stack média |
| `hermes-tokens` | Consommation de l'agent IA |

Les deux exporters maison sont des scripts Python sans dépendance externe, lancés par systemd
(unités dans [scripts/systemd](../scripts/systemd)). Si la collecte échoue, `proxmox_exporter.py`
répond `pve_exporter_status 0` au lieu de planter : la panne reste visible dans Prometheus.

## Règles

39 règles d'alerte réparties dans 5 fichiers, plus 6 règles d'enregistrement.

| Fichier | Alertes | Exemples |
| :--- | ---: | :--- |
| [alerts.yml](../monitoring/rules/alerts.yml) | 22 | `CibleInjoignable`, `ZpoolNonSain`, `ServiceHttpDown`, `CertificatSslExpire`, `ConteneurProxmoxArrete` |
| [alert_rules.yml](../monitoring/rules/alert_rules.yml) | 9 | Onduleur, piles des capteurs, disque plein prévu sous 3 jours, `Watchdog` |
| [backup.yml](../monitoring/rules/backup.yml) | 3 | `BackupJobEchoue`, `BackupStale`, `BackupFsReadonly` |
| [ups.yml](../monitoring/rules/ups.yml) | 3 | Mêmes noms que les alertes onduleur de `alert_rules.yml` |
| [hermes.yml](../monitoring/rules/hermes.yml) | 2 | Coût journalier, exporter arrêté |

Presque toutes les alertes ont une durée `for` (de 10 s à 1 h) : la condition doit durer avant
de déclencher, une valeur isolée ne suffit pas. `Watchdog` (`vector(1)`) est toujours active : si
elle disparaît de Discord, c'est la chaîne d'alerte qui est cassée.

### Consommation estimée par invité

[power.yml](../monitoring/rules/power.yml) répartit la puissance de l'hyperviseur entre ses
invités. La mesure vient d'une prise Zigbee lue par Home Assistant : environ 14 W au relevé, pour
un socle de 12 W.

1. `pve:node_idle_power_watts` : le socle, pris comme 5ᵉ centile des 3 derniers jours.
2. Le socle est réparti au prorata de la RAM de chaque invité.
3. Le reste (puissance actuelle moins le socle) est réparti au prorata du CPU consommé, calculé par
   `rate()` sur `pve_*_cpu_seconds_total`.

C'est un modèle, pas une mesure par invité : il sert à repérer un invité gourmand.

## Routage des alertes

[alertmanager.yml](../monitoring/alertmanager.yml) regroupe par `alertname` et `instance`, et
relance toutes les 4 h (1 h pour `critical`). L'URL du webhook Discord est lue dans un fichier
(`webhook_url_file`) monté depuis l'hôte, jamais écrite dans le dépôt.

## Limites

- Les alertes onduleur existent en double (`alert_rules.yml` et `ups.yml`) : une coupure produit
  deux notifications.
- `Watchdog` n'est reliée à aucun service externe : si Prometheus ou Alertmanager s'arrête, rien
  ne prévient automatiquement.
- Les exporters de la stack média ne sont pas versionnés ici.
