{ config, pkgs, ... }:

{
  imports = [
    ./kitty.nix
    ./starship.nix
  ];

  # 🐟 Fish Shell (Autosuggestions magiques et coloration syntaxique)
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting ""
      if test -f $HOME/.bash_aliases
        source $HOME/.bash_aliases
      end

      # Affichage d'un Pokémon aléatoire stylé à chaque ouverture
      if not set -q POKEMON_SHOWN; and test "$TERM" != "dumb"
        set -gx POKEMON_SHOWN 1
        ${pkgs.krabby}/bin/krabby random --no-title 2>/dev/null || ${pkgs.pokemon-colorscripts}/bin/pokemon-colorscripts -r --no-title 2>/dev/null
        echo ""
      end
    '';
    functions = {
      # 🌍 Fix Kitty SSH
      ssh = ''
        set -lx TERM xterm-256color
        command ssh $argv
      '';
      
      # 📁 Yazi Wrapper
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';
    };
  };

  # Shell interactif Bash (gardé en fallback)
  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      if [ -f $HOME/.bash_aliases ]; then
        . $HOME/.bash_aliases
      fi
      if [ -z "$POKEMON_SHOWN" ] && [ "$TERM" != "dumb" ] && [ -t 1 ]; then
        export POKEMON_SHOWN=1
        ${pkgs.krabby}/bin/krabby random --no-title 2>/dev/null || ${pkgs.pokemon-colorscripts}/bin/pokemon-colorscripts -r --no-title 2>/dev/null
        echo ""
      fi
      ssh() { TERM=xterm-256color command ssh "$@"; }
      y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then builtin cd -- "$cwd"; fi
        rm -f -- "$tmp"
      }
    '';
  };

  # Déplacement des alias au niveau global pour que Bash et Fish en profitent
  home.shellAliases = {
    # 🚀 NixOS & Maintenance Système (Alias simples)
    nix-upgrade = "sudo nixos-rebuild switch --flake /home/laurent/Config/NixOS-config-PCPDL#PCPDL && sudo chown -R $USER:users /home/laurent/Config/NixOS-config-PCPDL";
    nix-update = "sudo nix flake update --flake /home/laurent/Config/NixOS-config-PCPDL && sudo chown -R $USER:users /home/laurent/Config/NixOS-config-PCPDL";
    nix-clean = "sudo nix-collect-garbage -d && nix-collect-garbage -d";

    # Anciens alias (gardés au cas où par habitude)
    nrs = "nix-upgrade";
    nfu = "nix-update";
    ncg = "nix-clean";

    # 📁 Remplacement moderne de ls par eza (icônes + statut git)
    ls = "eza --icons";
    l = "eza -l --icons";
    ll = "eza -la --icons --git";
    la = "eza -a --icons";
    lt = "eza --tree --level=2 --icons";
    tree = "eza --tree --icons";

    # 📄 Remplacement moderne de cat par bat (coloration syntaxique)
    cat = "bat --paging=never";
    less = "bat";

    # 🎮 Raccourcis & Utilitaires
    poke = "krabby random";
    pokepic = "krabby random --no-title";
    wp = "random-wallpaper";
    c = "clear";

    # 🌐 Utilitaires SysAdmin & Réseaux
    ip = "ip -color";
    ports = "sudo lsof -i -P -n | grep LISTEN";
    ping = "ping -c 4";
    ndiff = "nvd diff $(ls -d1v /nix/var/nix/profiles/system-*-link | tail -n 2)";

    # 💽 Espace disque (Outils modernes)
    df = "duf";
    du = "dust";

    # ✨ Nouveaux Alias Pratiques
    ".." = "cd ..";
    "..." = "cd ../..";
    md = "mkdir -p";
    batman = "bat -l man -p";
  };

  # 🔍 Recherche floue interactive ultra-rapide (Ctrl+R pour l'historique, Ctrl+T pour les fichiers)
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" "--prompt='🔍 '" ];
    changeDirWidget.command = "fd --type d --hidden --exclude .git";
  };

  # ⚡ Saut de dossiers intelligent qui remplace la commande cd (zoxide)
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
  };

  # 📦 Environnements de développement isolés et automatiques (direnv + nix-direnv)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  # 💻 Moniteur système btop (géré par Home Manager pour hériter du thème Stylix)
  programs.btop = {
    enable = true;
    settings = {
      theme_background = false; # Transparence pour voir le fond d'écran
    };
  };

  # 📂 Gestionnaire de fichiers ultra-rapide (Yazi)
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy"; # garde le comportement historique (silence l'avertissement HM)
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  # 📜 Base de données SQLite pour l'historique bash/fish (Atuin)
  programs.atuin = {
    enable = true;
    enableBashIntegration = false; # Désactivé pour Bash (initialisé manuellement)
    enableFishIntegration = true;
    flags = [ "--disable-ctrl-r" ];
    settings = {
      auto_sync = false;
      daemon = {
        enabled = false;
        sync = false;
      };
      style = "compact";
      inline_height = 20;
    };
  };

  # 🖼️ Fastfetch (Remplaçant de Neofetch avec une tonne d'infos et un beau rendu)
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos";
        padding = {
          top = 2;
          left = 2;
          right = 2;
        };
      };
      display = {
        separator = " ➜  ";
        color = {
          keys = "magenta";
        };
        size = {
          maxPrefix = "MB";
          ndigits = 0;
        };
      };
      modules = [
        "break"
        "title"
        "separator"
        { type = "os"; key = " OS"; keyColor = "blue"; }
        { type = "host"; key = "󰌢 PC"; keyColor = "green"; }
        { type = "kernel"; key = " Kernel"; keyColor = "magenta"; }
        { type = "uptime"; key = "󰅐 Uptime"; keyColor = "red"; }
        { type = "packages"; key = "󰏖 Packages"; keyColor = "yellow"; }
        { type = "shell"; key = " Shell"; keyColor = "cyan"; }
        { type = "display"; key = "󰍹 Display"; keyColor = "blue"; }
        { type = "de"; key = " DE"; keyColor = "green"; }
        { type = "wm"; key = " WM"; keyColor = "magenta"; }
        { type = "wmtheme"; key = "󰉼 WM Theme"; keyColor = "red"; }
        { type = "theme"; key = "󰉼 Theme"; keyColor = "yellow"; }
        { type = "icons"; key = "󰉼 Icons"; keyColor = "cyan"; }
        { type = "font"; key = " Font"; keyColor = "blue"; }
        { type = "cursor"; key = "󰆿 Cursor"; keyColor = "green"; }
        { type = "terminal"; key = " Terminal"; keyColor = "magenta"; }
        { type = "terminalfont"; key = " Term Font"; keyColor = "red"; }
        { type = "cpu"; key = " CPU"; keyColor = "yellow"; }
        { type = "gpu"; key = "󰢮 GPU"; keyColor = "cyan"; }
        { type = "memory"; key = " Memory"; keyColor = "blue"; }
        { type = "swap"; key = "󰓡 Swap"; keyColor = "green"; }
        { type = "disk"; key = "󰋊 Disk"; keyColor = "magenta"; }
        { type = "localip"; key = "󰩠 Local IP"; keyColor = "red"; }
        { type = "battery"; key = " Battery"; keyColor = "yellow"; }
        { type = "poweradapter"; key = "󰚥 Power"; keyColor = "cyan"; }
        { type = "locale"; key = "󰌎 Locale"; keyColor = "blue"; }
        "break"
        "colors"
      ];
    };
  };
}
