{ config, pkgs, inputs, ... }:

{
  # Compte utilisateur principal
  users.users.laurent = {
    isNormalUser = true;
    description = "Laurent";
    extraGroups = [ "networkmanager" "wheel" "wireshark" "docker" "kvm" "libvirtd" ];

    packages = with pkgs; [
      # Navigateurs & Bureautique
      google-chrome
      firefox
      discord
      vlc
      obs-studio
      # 📄 Bureautique, Visionneuses & Utilitaires
      onlyoffice-desktopeditors # Suite bureautique complète (Word, Excel, PowerPoint)
      kdePackages.okular       # Lecteur & annotateur PDF professionnel (signature, formulaires)
      kdePackages.gwenview     # Visionneuse d'images avancée intégrée à Dolphin (recadrage, rotation)
      kdePackages.ark          # Gestionnaire d'archives (ZIP, 7z, RAR) intégré à Dolphin
      p7zip                    # Support des archives 7-Zip
      unrar                    # Extraction des archives RAR
      kdePackages.kdegraphics-thumbnailers # Miniatures d'images/photos dans Dolphin
      kdePackages.ffmpegthumbs # Miniatures et aperçus de vidéos dans Dolphin
      kdePackages.kservice     # Service de découverte d'applications KDE (kbuildsycoca6)
      kdePackages.kimageformats # Support étendu de tous les formats d'images dans Dolphin/Gwenview
      xournalpp                # Prise de notes manuscrites et signature de documents PDF
      # 💻 Terminal & Utilitaires Modernes
      krabby                   # Générateur ultra-rapide de Pokémon en couleurs/pixel-art
      pokemon-colorscripts     # Collection de Pokémon en couleurs ASCII/ANSI
      eza                      # Remplaçant moderne et coloré de ls (icônes, git, tree)
      bat                      # Remplaçant moderne de cat avec coloration syntaxique
      fzf                      # Recherche floue interactive (Ctrl+R / Ctrl+T)
      fd                       # Alternative plus rapide à 'find' (utilisé par fzf)
      ripgrep                  # Alternative plus rapide à 'grep' (utilisé par fzf)
      zoxide                   # Navigation intelligente et instantanée dans les dossiers (z)
      tealdeer                 # Remplaçant de 'man' avec des exemples pratiques (tldr)
      micro                    # Éditeur de texte en terminal ultra-simple et intuitif
      wl-clipboard             # Outils de presse-papier en ligne de commande (Wayland)
      wtype                    # Outil pour simuler la frappe au clavier (Wayland)
      winboat                  # Compatibilité & exécution d'applications Windows
      inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
      inputs.antigravity.packages."${pkgs.stdenv.hostPlatform.system}".google-antigravity-no-fhs
      inputs.antigravity.packages."${pkgs.stdenv.hostPlatform.system}".google-antigravity-ide-no-fhs

      # 💽 Utilitaires Disques & Clés USB
      gparted                  # Éditeur de partitions avancé
      gnome-disk-utility       # Utilitaire Disques (très pratique pour formater/monter/flasher)
      ventoy                   # Outil ultime pour créer des clés USB multi-boot (ISO)
      impression               # Créateur de clés USB bootables simple et moderne (GTK4)
      usbutils                 # Commandes utilitaires USB (lsusb)

      # Outils Système & Accessoires
      kitty                    # Émulateur de terminal accéléré GPU
      kdePackages.dolphin      # Gestionnaire de fichiers avancé (KDE)
      sops                     # Éditeur de secrets chiffrés pour sops-nix
      xdg-utils                # Utilitaires XDG (xdg-open, etc.)
      libnotify                # Pour les notifications (notify-send)

      # Multimédia & Streaming
      fladder                  # Client Jellyfin moderne et rapide
      spotify                  # Client Spotify officiel
      vlc                      # Lecteur multimédia universel (audio/vidéo)
      gimp                     # Retouche d'image (GIMP)
      handbrake                # Encodage & conversion vidéo
      obs-studio               # Enregistrement d'écran et streaming
      (pkgs.callPackage ./davinci-resolve.nix { })
      
      # Bureautique
      libreoffice-qt           # Suite bureautique complète (compatible MS Office)
      teams-for-linux          # Client Microsoft Teams pour Linux

      # Téléchargement & Jeux
      qbittorrent              # Client BitTorrent
      heroic                   # Launcher Epic Games / GOG

      # 🌐 Diagnostic Réseau & Contrôle à distance (NetAdmin)
      nmap                     # Scanner de ports et vulnérabilités
      tcpdump                  # Analyseur de trafic réseau en CLI
      iperf3                   # Outil de test de bande passante réseau
      mtr                      # Hybride Ping/Traceroute interactif
      dnsutils                 # Outils DNS (dig, nslookup)
      netcat-openbsd           # Couteau suisse réseau (TCP/UDP)
      socat                    # Relais bidirectionnel de flux de données
      iftop                    # Visualisation de la bande passante par connexion
      nethogs                  # Visualisation de la bande passante par processus

      bluetui                  # Gestionnaire Bluetooth TUI moderne
      localsend                # Partage de fichiers local P2P (style AirDrop)
      angryipscanner           # Scanner d'adresses IP / Réseau (équivalent Advanced IP Scanner)
      anydesk                  # Bureau à distance AnyDesk
      rustdesk-flutter         # Bureau à distance open-source RustDesk
      remmina                  # Client RDP, VNC et SSH de référence
      filezilla                # Client SFTP / FTP (équivalent WinSCP)
      nextcloud-client         # Client de synchronisation Nextcloud
      wireguard-tools          # Outils WireGuard VPN

      # 💻 Monitoring & Diagnostic Système (SysAdmin)
      htop                     # Le classique gestionnaire de tâches
      bottom                   # Un "top" graphique et ultra-rapide (en Rust)
      lsof                     # Liste les fichiers et sockets réseaux ouverts
      sysstat                  # iostat, mpstat, pidstat (analyse de perfs)
      strace                   # Traceur d'appels système
      smartmontools            # Vérification de santé S.M.A.R.T des disques
      kdePackages.filelight    # Visualiseur d'espace disque arborescent (équivalent WizTree)

      # 📄 Traitement de Logs & Terminal Avancé
      ripgrep                  # Remplaçant ultra-rapide de grep
      fd                       # Remplaçant moderne de find
      lnav                     # Navigateur de logs avancé (coloration, requêtes SQL)
      yq                       # Analyseur YAML en ligne de commande (équivalent jq)
      nvd                      # Différenciateur de versions NixOS (Nix Version Diff)
      # 🚀 Outils DevOps & Cloud Computing (Indispensables pour le Bachelor)
      zellij                   # Multiplexeur de terminal moderne (remplaçant de tmux)
      ansible                  # Automatisation et gestion de configuration (Infrastructure as Code)
      opentofu                 # Déploiement d'infrastructure Cloud/Proxmox (fork de Terraform)
      k9s                      # Interface TUI ultime pour administrer Kubernetes
      dive                     # Explorateur d'images Docker (analyse et optimisation des couches)
      termshark                # Wireshark dans le terminal (TUI pour tcpdump)
      doggo                    # Remplaçant moderne et coloré de dig/nslookup pour le DNS
      delta                    # Coloration syntaxique et mise en page avancée pour git diff
      duf                      # Remplaçant moderne de df (usage des disques et ZFS)
      dust                     # Remplaçant moderne de du (arborescence de l'espace disque)

      lazygit                  # Interface TUI magique pour Git
      lazydocker               # Interface TUI magique pour Docker

      # 🦀 Développement Rust
      rustc                    # Compilateur Rust officiel
      cargo                    # Gestionnaire de paquets et de projets Rust
      rustfmt                  # Formateur de code Rust
      clippy                   # Linter et conseils de code Rust
      rust-analyzer            # Serveur de langage (LSP) pour l'autocomplétion (Zed / Antigravity)
      cargo-watch              # Recompilation automatique à la sauvegarde
      cargo-edit               # Commandes cargo add/rm/upgrade

      # ⚙️ Développement C / C++
      gcc                      # Compilateur GCC
      clang                    # Compilateur Clang/LLVM
      clang-tools              # Outils Clang (clangd LSP pour l'autocomplétion, clang-format)
      cmake                    # Générateur de build CMake
      ninja                    # Moteur de compilation ultra-rapide
      gnumake                  # GNU Make
      gdb                      # Débogueur GNU
      lldb                     # Débogueur LLVM
      valgrind                 # Détection des fuites de mémoire (Memory leaks)
      pkg-config               # Résolution des bibliothèques C/C++

      # 🌐 Autres langages & Outils de développement
      python3                  # Interpréteur Python 3
      uv                       # Gestionnaire de paquets/environnements Python ultra-rapide
      nodejs                   # JavaScript / TypeScript
      powershell               # Interpréteur PowerShell (pwsh)
      gh                       # CLI officiel GitHub (gestion de dépôts / PRs)

      # 🌐 Environnement KDE Plasma & Utilitaires Graphiques
      kdePackages.spectacle    # Outil de capture d'écran puissant (zones, fenêtres, OCR, annotations)
      kdePackages.plasma-systemmonitor # Moniteur de ressources graphique KDE moderne
      kdePackages.kate         # Éditeur de texte avancé KDE
      kdePackages.kcalc        # Calculatrice intégrée KDE

      # Explorateur de fichiers & Samba / Réseau
      kdePackages.dolphin
      kdePackages.kio-extras  # Protocoles SMB (Samba), SFTP, etc. pour Dolphin
      kdePackages.kio-fuse    # Montage automatique des partages KIO
      kdePackages.kio-admin   # Actions administrateur KIO
      kdePackages.kservice    # Requis pour reconstruire le cache des applications (Open With)
      kdePackages.kio         # KIO Core pour la gestion des fichiers
      kdePackages.kde-cli-tools # Outils en ligne de commande KDE (ex: kbuildsycoca6, keditfiletype)
      cifs-utils              # Outils de montage de partages SMB/CIFS
      samba                   # Client Samba
      syncthing
    ];
  };

  # Activation de Steam avec règles pare-feu et optimisation
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Activation de Wireshark avec permissions pour l'utilisateur
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  # Paquets système globaux
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl

    kdePackages.qtdeclarative
    kdePackages.qtsvg
    kdePackages.qt5compat
    kdePackages.kwallet-pam
    nixfmt
    nixd
  ];

  # Polices système globales
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
    inter
  ];

  # Correction pour Dolphin (Open With vide hors KDE Plasma)
  environment.etc."xdg/menus/applications.menu".source = "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";
}
