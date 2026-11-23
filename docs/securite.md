# Sécurité

Relevé du 23/11/2026. Cette page sépare ce qui est actif, ce qui est seulement installé, et ce qui
manque.

## Exposition

Seuls les ports 80 et 443 de la Freebox sont redirigés, vers NPM Plus. Le DNS public passe par le
proxy Cloudflare : l'IP de la box n'apparaît pas dans les enregistrements DNS.

## Reverse proxy : NPM Plus (LXC 110)

- **TLS** terminé sur NPM Plus, certificats Let's Encrypt.
- **En-têtes** vérifiés sur le site public : `Strict-Transport-Security` (1 an,
  `includeSubDomains`), `Content-Security-Policy`, `X-Frame-Options: SAMEORIGIN`,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy` et `Permissions-Policy`.
- **Restriction d'accès** : 5 hôtes proxy sur 18 n'acceptent que le LAN (`allow` réseau privé,
  puis `deny all`). Les autres sont joignables depuis Internet et reposent sur la connexion propre
  à chaque application.

## CrowdSec

CrowdSec tourne dans un conteneur à côté de NPM Plus. Il lit les journaux nginx, repère les
comportements suspects (scans, force brute, exploitation de CVE connues) et publie des décisions
de blocage. Le bouncer intégré à NPM Plus (`npmplus-bouncer`) récupère ces décisions et refuse les
adresses bannies. Collections actives : scénarios HTTP de base, CVE HTTP, WordPress, Linux, sshd.

**AppSec (pare-feu applicatif) : installé, pas branché.** Les règles AppSec sont chargées dans
CrowdSec, mais le bouncer n'a pas d'`APPSEC_URL` : aucune requête n'est soumise à l'inspection.

## Authentification centralisée : pas branchée

Authelia (LXC 113) et Pocket-ID (LXC 138) tournent, mais :

- aucun hôte proxy n'appelle `auth_request` (les seules occurrences sont `auth_request off` sur les
  chemins ACME) ;
- Pocket-ID n'a aucun client OIDC déclaré ;
- la politique par défaut d'Authelia est `one_factor`.

Aucun service n'est donc protégé par SSO ni par double authentification.

## Conteneurs LXC

36 LXC sur 42 sont **non privilégiés** : le root du conteneur correspond à un utilisateur sans
droits sur l'hôte (décalage d'UID). S'échapper du conteneur ne donne pas root sur l'hyperviseur.

6 sont **privilégiés** : 102, 103, 105, 114, 115 et 141. Le plus sensible est le LXC 105, qui
héberge Docker et la plupart des stacks. Le convertir demande de réattribuer tous ses fichiers
avec le décalage d'UID, d'où le report.

## Déploiement du site

Le webhook de déploiement (voir [ci-cd.md](ci-cd.md)) :

- vérifie la signature HMAC-SHA256 envoyée par Gitea (`X-Gitea-Signature`) ;
- n'accepte que `refs/heads/main` ;
- refuse de démarrer si le secret fait moins de 32 caractères (`ExecStartPre`) ;
- tourne sous l'utilisateur `astro`, sans droits root.

## Secrets

Aucun secret dans ce dépôt. Chaque stack liste ses variables dans `.env.example`, sans valeur.
Les secrets d'exécution sont dans des fichiers hors dépôt, lus par fichier quand le logiciel le
permet (`webhook_url_file` d'Alertmanager, fichier d'environnement du webhook). La CI passe
gitleaks sur tout l'historique Git.

## Ce qui manque

| Manque | Conséquence |
| :--- | :--- |
| AppSec CrowdSec non branché | Le contenu des requêtes n'est pas inspecté |
| SSO non branché | Les services publics reposent sur leur propre login |
| Pas de fail2ban sur Gitea ni sur le LXC du site | Seul CrowdSec, au niveau du proxy, freine la force brute |
| 6 LXC privilégiés | Une évasion depuis ces conteneurs donne root sur l'hôte |
| Réseau plat, sans pare-feu entre invités | Aucun cloisonnement (voir [architecture-reseau.md](architecture-reseau.md)) |
| n8n en HTTP avec `N8N_SECURE_COOKIE=false` | Cookie de session lisible sur le LAN |
