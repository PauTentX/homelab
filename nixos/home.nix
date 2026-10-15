{ config, pkgs, ... }:

{
  home.username = "laurent";
  home.homeDirectory = "/home/laurent";

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Laurent";
        email = "laurent@example.com"; # À changer avec ton email
      };
      credential = {
        helper = "store"; # Mémorise identifiant et mot de passe pour ne plus les redemander
      };
    };
  };

  # --- Terminal et Shell ---
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting ""
    '';
    shellAliases = {
      nos = "sudo nixos-rebuild switch --flake .#PCPDL";
      nob = "nix build .#nixosConfigurations.PCPDL.config.system.build.toplevel";
      ls = "eza --icons auto";
      ll = "eza -lha --icons auto --git";
      tree = "eza --tree --icons auto";
      cat = "bat";
      grep = "rg";
    };
  };


  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.kitty = {
    enable = true;
    settings = {
      scrollback_lines = 10000;
      enable_audio_bell = false;
      window_padding_width = 10;
      confirm_os_window_close = 0; # Désactive la confirmation énervante à la fermeture
    };
  };

  # Un prompt Bash magnifique (Starship)
  programs.bash.enable = true;


  # --- Scripts personnalisés (Menu Démarrer & Power Menu) ---
  home.packages = [
    (pkgs.writeShellScriptBin "start-menu" ''
      apps="🚀 Toutes les applications"
      zen="🌐 Zen Browser"
      ide="💻 Antigravity IDE"
      files="📁 Fichiers (Dolphin)"
      display="🖥️  Écrans (nwg-displays)"
      audio="🔊 Son (Pavucontrol)"
      wifi="📶 Réseau (Wifi)"
      screenshot_window="🖼️  Capture d'écran (Fenêtre)"
      screenshot_zone="✂️  Capture d'écran (Zone)"
      screenshot_full="🖥️  Capture d'écran (Tout l'écran)"
      lock="🔒 Verrouiller la session"
      suspend="💤 Mettre en veille"
      reboot="🔄 Redémarrer"
      shutdown="🛑 Éteindre le PC"

      options="$apps\n$zen\n$ide\n$files\n$display\n$audio\n$wifi\n$screenshot_window\n$screenshot_zone\n$screenshot_full\n$lock\n$suspend\n$reboot\n$shutdown"

      chosen=$(echo -e "$options" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Menu Démarrer" --width 360 --height 520 --cache-file /dev/null)

      case "$chosen" in
        "$apps")
          ${pkgs.wofi}/bin/wofi --show drun
          ;;
        "$zen")
          zen &
          ;;
        "$ide")
          google-antigravity-ide &
          ;;
        "$files")
          dolphin &
          ;;
        "$display")
          nwg-displays &
          ;;
        "$audio")
          pavucontrol &
          ;;
        "$wifi")
          nm-connection-editor &
          ;;
        "$screenshot_window")
          grim -g "$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | wl-copy && ${pkgs.libnotify}/bin/notify-send "Capture d'écran" "Fenêtre active copiée dans le presse-papier"
          ;;
        "$screenshot_zone")
          grim -g "$(slurp)" - | wl-copy && ${pkgs.libnotify}/bin/notify-send "Capture d'écran" "Zone copiée dans le presse-papier"
          ;;
        "$screenshot_full")
          grim - | wl-copy && ${pkgs.libnotify}/bin/notify-send "Capture d'écran" "Écran complet copié dans le presse-papier"
          ;;
        "$lock")
          hyprlock
          ;;
        "$suspend")
          systemctl suspend
          ;;
        "$reboot")
          systemctl reboot
          ;;
        "$shutdown")
          systemctl poweroff
          ;;
      esac
    '')

    (pkgs.writeShellScriptBin "power-menu" ''
      lock="🔒 Verrouiller"
      suspend="💤 Mise en veille"
      reboot="🔄 Redémarrer"
      shutdown="🛑 Éteindre"

      chosen=$(echo -e "$lock\n$suspend\n$reboot\n$shutdown" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Session" --width 260 --height 220 --cache-file /dev/null)

      case "$chosen" in
        "$lock")
          hyprlock
          ;;
        "$suspend")
          systemctl suspend
          ;;
        "$reboot")
          systemctl reboot
          ;;
        "$shutdown")
          systemctl poweroff
          ;;
      esac
    '')
  ];

  # --- Waybar ---
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [
          "custom/menu"
          "hyprland/workspaces"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "network"
          "bluetooth"
          "pulseaudio"
          "backlight"
          "battery"
        ];

        "custom/menu" = {
          format = "";
          tooltip-format = "Menu Démarrer\n• Clic Gauche : Menu rapide\n• Clic Droit : Menu d'extinction";
          on-click = "start-menu";
          on-click-right = "power-menu";
        };

        "network" = {
          format-wifi = "  {essid}";
          format-ethernet = "󰈀  {ipaddr}";
          format-disconnected = "󰤮  Déconnecté";
          on-click = "nm-connection-editor";
          tooltip-format = "Wifi / Réseau";
        };

        "bluetooth" = {
          format = " {status}";
          format-connected = "󰂱 {device_alias}";
          format-connected-battery = "󰂱 {device_alias} 󰥉 {device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 Muet";
          format-icons = {
            headphone = "󰋋";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
        };

        "backlight" = {
          format = "{icon} {percent}%";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃠"
          ];
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%- -n 5%";
          tooltip-format = "Luminosité : {percent}% (Molette pour ajuster)";
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰂄 {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };

        "clock" = {
          format = "  {:%H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "Noto Sans", sans-serif;
        font-size: 14px;
        color: #cdd6f4;
      }

      window#waybar {
        background-color: #1e1e2e;
        border-bottom: 2px solid #8839ef; /* Violet plus sombre */
      }

      #custom-menu {
        font-size: 18px;
        color: #cba6f7;
        padding: 0 12px 0 10px;
        margin-right: 2px;
        transition: all 0.2s ease-in-out;
      }

      #custom-menu:hover {
        color: #ffffff;
        background-color: #8839ef;
        border-radius: 5px;
      }

      #workspaces button {
        padding: 0 10px;
        color: #cdd6f4;
      }

      #workspaces button.active {
        background-color: #8839ef; /* Violet sombre pour un meilleur contraste */
        color: #ffffff; /* Texte en blanc éclatant */
        border-radius: 5px;
      }

      #clock, #battery, #backlight, #pulseaudio, #network, #bluetooth {
        padding: 0 15px;
      }
    '';
  };

  # --- Hyprland ---
  xdg.configFile."hypr/hyprland.conf".text = ''
    # On charge le fichier généré par nwg-displays (pour gérer les écrans graphiquement)
    source = ~/.config/hypr/monitors.conf

    exec-once = waybar
    exec-once = hyprctl setcursor capitaine-cursors 24
    exec-once = hyprpaper
    exec-once = hypridle
    exec-once = ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1
    exec-once = swaync
    
    # Historique du presse-papier
    exec-once = wl-paste --type text --watch cliphist store
    exec-once = wl-paste --type image --watch cliphist store

    input {
      kb_layout = fr
    }

    general {
      col.active_border = rgba(8839efee) rgba(89b4faee) 45deg
      col.inactive_border = rgba(585b70aa)
      border_size = 2
      gaps_in = 2   # Plus petit gap interne
      gaps_out = 4  # Plus petit gap externe
    }

    decoration {
      rounding = 10
      blur {
          enabled = true
          size = 3
          passes = 1
      }
      shadow {
        enabled = true
        range = 4
        render_power = 3
        color = rgba(1a1a1aee)
      }
    }

    animations {
      enabled = true
      bezier = myBezier, 0.05, 0.9, 0.1, 1.05
      animation = windows, 1, 7, myBezier
      animation = windowsOut, 1, 7, default, popin 80%
      animation = border, 1, 10, default
      animation = fade, 1, 7, default
      animation = workspaces, 1, 6, default
    }

    # Raccourcis de base & Gestion des fenêtres
    bind = SUPER, Q, killactive
    bind = SUPER, F, fullscreen, 1
    bind = SUPER, V, togglefloating
    bind = SUPER, M, exit
    bind = SUPER, C, centerwindow # Centrer la fenêtre flottante

    # Lancement d'applications
    bind = SUPER, Return, exec, kitty
    bind = SUPER, Z, exec, zen
    bind = SUPER, A, exec, google-antigravity-ide
    bind = SUPER, E, exec, dolphin

    # Menus, Lanceurs et Outils
    bind = SUPER, SPACE, exec, wofi --show drun
    bind = SUPER, D, exec, start-menu
    bind = SUPER, Escape, exec, power-menu
    bind = SUPER, period, exec, wofi-emoji # Sélecteur d'Emojis
    bind = SUPER SHIFT, V, exec, cliphist list | wofi --dmenu --prompt "Presse-papier" | cliphist decode | wl-copy # Historique presse-papier
    bind = SUPER, B, exec, killall -SIGUSR1 waybar # Cacher/Montrer Waybar

    # Verrouillage de l'écran
    bind = SUPER, L, exec, hyprlock

    # --- Captures d'écran ---
    # Impr. Écran = Tout l'écran
    bind = , Print, exec, grim - | wl-copy && ${pkgs.libnotify}/bin/notify-send "Capture d'écran" "Écran complet copié dans le presse-papier"
    # Ctrl + Impr. Écran = Fenêtre active uniquement
    bind = CONTROL, Print, exec, grim -g "$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '\"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])\"')" - | wl-copy && ${pkgs.libnotify}/bin/notify-send "Capture d'écran" "Fenêtre active copiée dans le presse-papier"
    # Super + Impr. Écran (ou Super + Maj + S) = Sélection d'une zone
    bind = SUPER, Print, exec, grim -g "$(slurp)" - | wl-copy && ${pkgs.libnotify}/bin/notify-send "Capture d'écran" "Zone copiée dans le presse-papier"
    bind = SUPER SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy && ${pkgs.libnotify}/bin/notify-send "Capture d'écran" "Zone copiée dans le presse-papier"

    # Contrôles de volume et de luminosité
    binde = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
    binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    binde = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    binde = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
    binde = , XF86MonBrightnessDown, exec, brightnessctl set 5%- -n 5%

    # --- NOUVEAU : Navigation avec les Flèches ---
    # Changer le focus (sélection) de la fenêtre avec Super + Flèches
    bind = SUPER, left, movefocus, l
    bind = SUPER, right, movefocus, r
    bind = SUPER, up, movefocus, u
    bind = SUPER, down, movefocus, d

    # Déplacer physiquement la fenêtre avec Super + Maj + Flèches
    bind = SUPER SHIFT, left, movewindow, l
    bind = SUPER SHIFT, right, movewindow, r
    bind = SUPER SHIFT, up, movewindow, u
    bind = SUPER SHIFT, down, movewindow, d

    # Changement d'espaces de travail (Workspaces) - Adapté pour clavier AZERTY
    bind = SUPER, ampersand, workspace, 1
    bind = SUPER, eacute, workspace, 2
    bind = SUPER, quotedbl, workspace, 3
    bind = SUPER, apostrophe, workspace, 4
    bind = SUPER, parenleft, workspace, 5
    bind = SUPER, minus, workspace, 6
    bind = SUPER, egrave, workspace, 7
    bind = SUPER, underscore, workspace, 8
    bind = SUPER, ccedilla, workspace, 9
    bind = SUPER, agrave, workspace, 10

    # Déplacer une fenêtre vers un autre espace de travail (Maj + Windows + Chiffre)
    bind = SUPER SHIFT, ampersand, movetoworkspace, 1
    bind = SUPER SHIFT, eacute, movetoworkspace, 2
    bind = SUPER SHIFT, quotedbl, movetoworkspace, 3
    bind = SUPER SHIFT, apostrophe, movetoworkspace, 4
    bind = SUPER SHIFT, parenleft, movetoworkspace, 5
    bind = SUPER SHIFT, minus, movetoworkspace, 6
    bind = SUPER SHIFT, egrave, movetoworkspace, 7
    bind = SUPER SHIFT, underscore, movetoworkspace, 8
    bind = SUPER SHIFT, ccedilla, movetoworkspace, 9
    bind = SUPER SHIFT, agrave, movetoworkspace, 10

    # Règles de fenêtres flottantes
    windowrule {
      name = pavucontrol-float
      match:class = ^(pavucontrol)$
      float = 1
    }
    windowrule {
      name = nwg-displays-float
      match:class = ^(nwg-displays)$
      float = 1
    }
  '';

  # --- Configurations Annexes ---
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ~/.config/hypr/assets/wallpaper.jpg
    wallpaper = , ~/.config/hypr/assets/wallpaper.jpg
  '';

  xdg.configFile."hypr/hyprlock.conf".text = ''
    background {
      monitor =
      path = ~/.config/hypr/assets/wallpaper.jpg
      blur_passes = 1
      blur_size = 7
      noise = 0.0117
      contrast = 0.8916
      brightness = 0.8172
      vibrancy = 0.1696
      vibrancy_darkness = 0.0
    }

    input-field {
      monitor =
      size = 200, 50
      outline_thickness = 3
      dots_size = 0.33
      dots_spacing = 0.15
      dots_center = true
      outer_color = rgb(8839ef)
      inner_color = rgb(1e1e2e)
      font_color = rgb(cdd6f4)
      fade_on_empty = true
      placeholder_text = <i>Mot de passe...</i>
      hide_input = false
      position = 0, -20
      halign = center
      valign = center
    }

    label {
      monitor =
      text = $TIME
      color = rgba(205, 214, 244, 1.0)
      font_size = 55
      font_family = Noto Sans
      position = 0, 80
      halign = center
      valign = center
    }
  '';

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      lock_cmd = pidof hyprlock || hyprlock       # évite de lancer plusieurs instances
      before_sleep_cmd = loginctl lock-session    # verrouille avant de s'endormir
      after_sleep_cmd = hyprctl dispatch dpms on  # rallume l'écran
    }

    listener {
      timeout = 300                                 # 5 minutes
      on-timeout = loginctl lock-session            # verrouille l'écran
    }

    listener {
      timeout = 330                                 # 5.5 minutes
      on-timeout = hyprctl dispatch dpms off        # éteint l'écran
      on-resume = hyprctl dispatch dpms on          # rallume l'écran
    }
  '';

  # --- Configuration et Style de Wofi (Thème Catppuccin Mocha) ---
  xdg.configFile."wofi/config".text = ''
    width=380
    height=460
    location=top_left
    xoffset=12
    yoffset=40
    prompt=Rechercher...
    filter_rate=100
    allow_markup=true
    no_actions=true
    insensitive=true
    allow_images=true
    image_size=24
    gtk_dark=true
  '';

  xdg.configFile."wofi/style.css".text = ''
    window {
      margin: 0px;
      background-color: #1e1e2e;
      border-radius: 12px;
      border: 2px solid #8839ef;
      font-family: "JetBrainsMono Nerd Font", sans-serif;
      font-size: 14px;
    }

    #input {
      margin: 10px;
      border-radius: 8px;
      border: none;
      background-color: #313244;
      color: #cdd6f4;
      padding: 8px 12px;
    }

    #input:focus {
      border: 2px solid #8839ef;
    }

    #inner-box {
      margin: 5px;
      padding: 5px;
      background-color: #1e1e2e;
    }

    #outer-box {
      margin: 5px;
      padding: 5px;
      background-color: #1e1e2e;
    }

    #scroll {
      margin: 0px;
    }

    #text {
      margin: 5px;
      color: #cdd6f4;
    }

    #entry {
      padding: 8px 12px;
      border-radius: 8px;
      margin: 3px 0px;
    }

    #entry:selected {
      background-color: #8839ef;
      color: #ffffff;
    }

    #entry:selected #text {
      color: #ffffff;
      font-weight: bold;
    }
  '';

  # --- Centre de notifications SwayNC ---
  services.swaync = {
    enable = true;
  };

  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}
