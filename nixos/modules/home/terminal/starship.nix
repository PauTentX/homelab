{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      # Délais de scan (Très court pour éviter les énormes lags sur les gros dossiers Git)
      scan_timeout = 100;
      command_timeout = 150;

      # Format global à 2 lignes avec un maximum d'informations utiles pour le SysAdmin
      format = ''
        [╭─](bold mauve)$os$username$hostname$localip$shlvl$kubernetes$directory$git_branch$git_status$git_metrics$nix_shell$direnv$rust$c$python$nodejs$docker_context$memory_usage$cmd_duration$status$time
        [╰─](bold mauve)$character
      '';

      # 🐧 Système d'exploitation (NixOS)
      os = {
        disabled = false;
        symbols = {
          NixOS = " ";
        };
        style = "bold cyan";
        format = "[$symbol]($style)";
      };

      # 👤 Utilisateur & Machine
      username = {
        show_always = false;
        style_user = "bold lavender";
        format = "[$user]($style) ";
      };

      hostname = {
        ssh_only = true;
        style = "bold peach";
        format = "@[$hostname]($style) ";
      };

      # 📁 Répertoire courant (chemin complet intelligent)
      directory = {
        style = "bold blue";
        read_only = " 🔒";
        read_only_style = "red";
        truncation_length = 5;
        truncate_to_repo = true;
        format = "[$path]($style)[$read_only]($read_only_style) ";
      };

      # 🌿 Git (Branche & Statut détaillé)
      git_branch = {
        symbol = " ";
        style = "bold mauve";
        format = "on [$symbol$branch]($style) ";
      };

      git_status = {
        style = "bold red";
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
        conflicted = "🏳️ ";
        ahead = "⇡$count ";
        behind = "⇣$count ";
        diverged = "⇕⇡$ahead_count⇣$behind_count ";
        untracked = "?$count ";
        stashed = "📦 ";
        modified = "!$count ";
        staged = "+$count ";
        renamed = "»$count ";
        deleted = "✘$count ";
      };

      # ❄️ Environnement Nix-shell & Direnv
      nix_shell = {
        symbol = " ";
        style = "bold sky";
        format = "via [$symbol$state]($style) ";
      };

      direnv = {
        disabled = false;
        symbol = "direnv ";
        style = "bold teal";
        format = "[$symbol]($style)";
      };

      # 🦀 Rust (Version du compilateur)
      rust = {
        symbol = "󱘗 ";
        style = "bold flamingo";
        format = "via [$symbol($version )]($style)";
      };

      # ⚙️ C / C++
      c = {
        symbol = " ";
        style = "bold sapphire";
        format = "via [$symbol($version )]($style)";
      };

      # 🐍 Python (Version & Environnement virtuel venv)
      python = {
        symbol = " ";
        style = "bold yellow";
        format = "via [$symbol($version )(\\($virtualenv\\) )]($style)";
      };

      # 🟢 Node.js
      nodejs = {
        symbol = "󰎙 ";
        style = "bold green";
        format = "via [$symbol($version )]($style)";
      };

      # 🐳 Docker
      docker_context = {
        symbol = " ";
        style = "bold blue";
        format = "via [$symbol$context]($style) ";
      };

      # ⏱️ Durée d'exécution de la commande (si > 1s)
      cmd_duration = {
        min_time = 1000;
        style = "bold yellow";
        format = "took [$duration]($style) ";
      };

      # ⚡ Statut de retour d'erreur
      status = {
        disabled = false;
        symbol = "✖ ";
        success_symbol = "";
        format = "[$symbol$status]($style) ";
        style = "bold red";
      };

      # 🕒 Heure actuelle
      time = {
        disabled = false;
        time_format = "%R";
        style = "bold overlay1";
        format = "at [ $time]($style) ";
      };

      # 🚀 Curseur de saisie dynamique
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold yellow)";
      };

      # 🌐 Adresse IP Locale (Idéal pour SSH / Serveurs)
      localip = {
        ssh_only = false;
        format = "at [🌐 $localipv4]($style) ";
        style = "bold cyan";
        disabled = false;
      };

      # 🐚 Niveau d'imbrication du Shell (Très utile avec Zellij / Tmux)
      shlvl = {
        disabled = false;
        symbol = "↕️ ";
        style = "bold yellow";
        format = "[$symbol$shlvl]($style) ";
        threshold = 2;
      };

      # ☸️ Kubernetes (Context & Namespace)
      kubernetes = {
        disabled = false;
        symbol = "☸ ";
        style = "bold blue";
        format = "via [$symbol$context( \\($namespace\\))]($style) ";
      };

      # 📈 Git Metrics (Lignes ajoutées/supprimées)
      git_metrics = {
        disabled = false;
        added_style = "bold green";
        deleted_style = "bold red";
        format = "([+$added]($added_style) )([-$deleted]($deleted_style) )";
      };

      # 🐏 Utilisation de la RAM (Affiché si > 70%)
      memory_usage = {
        disabled = false;
        threshold = 70;
        symbol = "🐏 ";
        style = "bold red";
        format = "via [$symbol$ram_pct]($style) ";
      };
    };
  };
}
