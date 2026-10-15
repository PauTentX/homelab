{ config, pkgs, lib, ... }:

let
  # Thème d'icônes Papirus avec dossiers Catppuccin Mocha Mauve
  catppuccinIcons = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "mauve";
  };

  # Thème KDE officiel Catppuccin Mocha (avec décorations Modernes et schémas Mauve/Blue)
  catppuccinKde = pkgs.catppuccin-kde.override {
    flavour = [ "mocha" ];
    accents = [ "mauve" "blue" ];
    winDecStyles = [ "modern" ];
  };

  # Fond d'écran par défaut
  defaultWallpaper = "/home/laurent/Config/NixOS-config-PCPDL/Wallpapers/pixelart_night_train_cozy_gas_RoyalNaym.png";
in
{
  # Désactiver le target KDE et Qt de Stylix au niveau Home Manager :
  # 1. Stylix ne supporte pas encore le backend natif 'kde' pour Qt (déclenche un warning)
  # 2. Cela laisse plasma-manager gérer à 100% le thème officiel Catppuccin sans interférence
  stylix.targets.kde.enable = lib.mkForce false;
  stylix.targets.qt.enable = lib.mkForce false;

  home.packages = [
    catppuccinIcons
    catppuccinKde
    pkgs.catppuccin-cursors.mochaMauve
    pkgs.playerctl
    (pkgs.writeShellScriptBin "set-wallpaper" ''
      IMG="$1"
      if [ -z "$IMG" ]; then
        echo "Usage: set-wallpaper /chemin/vers/image.jpg"
        exit 1
      fi
      if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
        plasma-apply-wallpaperimage "$IMG"
      fi
    '')
    (pkgs.writeShellScriptBin "random-wallpaper" ''
      WP_DIR="/home/laurent/Config/NixOS-config-PCPDL/Wallpapers"
      [ ! -d "$WP_DIR" ] && WP_DIR="$HOME/.config/wallpapers"
      if [ -d "$WP_DIR" ]; then
        IMG=$(find "$WP_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
        if [ -n "$IMG" ]; then
          plasma-apply-wallpaperimage "$IMG"
          notify-send -i "$IMG" "Fond d'écran changé" "$(basename "$IMG")"
        fi
      fi
    '')
  ];

  programs.plasma = {
    enable = true;

    # 1. Gestion de l'espace de travail et apparence
    workspace = {
      clickItemTo = "select"; # Clic simple sélectionne, double clic ouvre (comportement moderne)
      colorScheme = "CatppuccinMochaMauve";
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };
      iconTheme = "Papirus-Dark";
      # Note : géré en diaporama automatique via configFile ci-dessous
      # wallpaper = defaultWallpaper;
    };

    # Diaporama automatique de fonds d'écran (KDE Slideshow natif)
    configFile."plasma-org.kde.plasma.desktop-appletsrc" = {
      "Containments/1" = {
        "wallpaperplugin" = "org.kde.slideshow";
      };
      "Containments/1/Wallpaper/org.kde.slideshow/General" = {
        "SlidePaths" = "/home/laurent/Config/NixOS-config-PCPDL/Wallpapers";
        "SlideInterval" = "900"; # 15 minutes
        "Randomize" = "true";
      };
    };

    # 2. Polices d'écriture cohérentes (Inter pour l'UI, Meslo pour le code/terminal)
    fonts = {
      general = {
        family = "Inter";
        pointSize = 10;
      };
      fixedWidth = {
        family = "MesloLGS Nerd Font";
        pointSize = 11;
      };
      small = {
        family = "Inter";
        pointSize = 8;
      };
      toolbar = {
        family = "Inter";
        pointSize = 10;
      };
      menu = {
        family = "Inter";
        pointSize = 10;
      };
      windowTitle = {
        family = "Inter";
        pointSize = 10;
      };
    };

    # 3. Effets de fenêtres KWin & Navigation
    kwin = {
      cornerBarrier = false;
      effects = {
        blur = {
          enable = true;
        };
        translucency = {
          enable = true;
        };
        shakeCursor = {
          enable = true; # Secouer la souris agrandit le curseur pour le repérer
        };
        wobblyWindows = {
          enable = false;
        };
      };
      nightLight = {
        enable = true;
        mode = "times";
        time = {
          evening = "20:30";
          morning = "07:00";
        };
        temperature = {
          night = 4000;
        };
      };
    };

    # Configuration fine KWin (Coins actifs / Hot Corners)
    # ElectricBorderTopLeft = 7 correspond à l'action "Overview" (Vue d'ensemble)
    configFile."kwinrc"."ElectricBorders" = {
      "TopLeft" = "Overview";
    };

    # 4. Raccourcis clavier (KRunner, Spectacle, Terminal, Verrouillage)
    shortcuts = {
      krunner = {
        "run command" = [ "Alt+Space" "Meta+Space" ];
      };
      org_kde_krunner = {
        "_launch" = [ "Alt+Space" "Meta+Space" ];
      };
      plasmashell = {
        "activate application launcher" = "Meta";
      };
      ksmserver = {
        "Lock Session" = [ "Meta+L" "Screensaver" ];
      };
      kwin = {
        "Overview" = "Meta+Tab";
        "Expose" = "Ctrl+F9";
        "Window Close" = "Meta+Q";
        "Window Maximize" = "Meta+F";
        "Window Minimize" = "Meta+M";
        # Snapping flottant rapide sans auto-tiling (Quick Tile)
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Window Quick Tile Top" = "Meta+Up";
        "Window Quick Tile Bottom" = "Meta+Down";
        # Déplacement entre bureaux virtuels (Touches physiques AZERTY 1 à 5)
        "Switch to Desktop 1" = "Meta+Ampersand";
        "Switch to Desktop 2" = "Meta+Eacute";
        "Switch to Desktop 3" = "Meta+Quotedbl";
        "Switch to Desktop 4" = "Meta+Apostrophe";
        "Switch to Desktop 5" = "Meta+Parenleft";
        "Window to Desktop 1" = "Meta+Shift+Ampersand";
        "Window to Desktop 2" = "Meta+Shift+Eacute";
        "Window to Desktop 3" = "Meta+Shift+Quotedbl";
        "Window to Desktop 4" = "Meta+Shift+Apostrophe";
        "Window to Desktop 5" = "Meta+Shift+Parenleft";
      };
      spectacle = {
        "CaptureActiveWindow" = "Ctrl+Print";
        "CaptureCurrentMonitor" = "Print";
        "RectangularRegionScreenShot" = [ "Meta+Shift+S" "Meta+Print" ];
      };
    };

    # 5. Disposition du panneau (Taskbar Plasma épurée avec Application Launcher, Pager, Icons, Systray, Horloge)
    panels = [
      {
        location = "bottom";
        height = 44;
        floating = true;
        alignment = "center";
        widgets = [
          {
            name = "org.kde.plasma.kickoff";
            config = {
              General = {
                icon = "nix-snowflake";
              };
            };
          }
          {
            name = "org.kde.plasma.pager";
          }
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General = {
                launchers = [
                  "applications:zen-beta.desktop"
                  "applications:kitty.desktop"
                  "applications:org.kde.dolphin.desktop"
                  "applications:code.desktop"
                  "applications:spotify.desktop"
                ];
              };
            };
          }
          {
            name = "org.kde.plasma.systemtray";
          }
          {
            name = "org.kde.plasma.digitalclock";
            config = {
              Appearance = {
                dateFormat = "shortDate";
                showDate = true;
                use24hFormat = 2;
              };
            };
          }
        ];
      }
    ];
  };
}
