{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./terminal
    ./git.nix
    ./vscode.nix
    ./calendar.nix
    ./plasma.nix
    ./hermes
  ];

  # Informations utilisateur Home Manager
  home.username = "laurent";
  home.homeDirectory = "/home/laurent";
  home.stateVersion = "26.05";

  # Raccourci vers le partage Samba monté
  home.file."BacASable".source = config.lib.file.mkOutOfStoreSymlink "/mnt/BacASable";

  # Dossier de fonds d'écran centralisé
  home.file.".config/wallpapers".source = ../../Wallpapers;

  # Associations de fichiers par défaut (MIME types pour Dolphin / xdg-open)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # 🖼️ Images -> Gwenview
      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/jpg" = [ "org.kde.gwenview.desktop" ];
      "image/pjpeg" = [ "org.kde.gwenview.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "image/x-png" = [ "org.kde.gwenview.desktop" ];
      "image/webp" = [ "org.kde.gwenview.desktop" ];
      "image/gif" = [ "org.kde.gwenview.desktop" ];
      "image/svg+xml" = [ "org.kde.gwenview.desktop" ];
      "image/bmp" = [ "org.kde.gwenview.desktop" ];
      "image/x-bmp" = [ "org.kde.gwenview.desktop" ];
      "image/x-ms-bmp" = [ "org.kde.gwenview.desktop" ];
      "image/tiff" = [ "org.kde.gwenview.desktop" ];
      "image/x-icon" = [ "org.kde.gwenview.desktop" ];
      "image/x-ico" = [ "org.kde.gwenview.desktop" ];
      "image/avif" = [ "org.kde.gwenview.desktop" ];
      "image/heic" = [ "org.kde.gwenview.desktop" ];
      "image/heif" = [ "org.kde.gwenview.desktop" ];
      "image/jxl" = [ "org.kde.gwenview.desktop" ];

      # 📑 Documents PDF & Ebooks -> Okular
      "application/pdf" = [ "org.kde.okular.desktop" ];
      "application/epub+zip" = [ "org.kde.okular.desktop" ];
      "application/x-mobipocket-ebook" = [ "org.kde.okular.desktop" ];

      # 📝 Fichiers texte & code -> VSCode
      "text/plain" = [ "code.desktop" "org.gnome.TextEditor.desktop" ];
      "text/markdown" = [ "code.desktop" "org.gnome.TextEditor.desktop" ];
      "text/x-nix" = [ "code.desktop" "org.gnome.TextEditor.desktop" ];
      "application/json" = [ "code.desktop" "org.gnome.TextEditor.desktop" ];
      "application/x-yaml" = [ "code.desktop" "org.gnome.TextEditor.desktop" ];
      "application/xml" = [ "code.desktop" "org.gnome.TextEditor.desktop" ];
      "text/csv" = [ "code.desktop" "org.gnome.TextEditor.desktop" ];

      # 📊 Bureautique (Word, Excel, PowerPoint) -> OnlyOffice
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/msword" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.ms-excel" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.ms-powerpoint" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.text" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.spreadsheet" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.presentation" = [ "onlyoffice-desktopeditors.desktop" ];

      # 🗜️ Archives -> Ark
      "application/zip" = [ "org.kde.ark.desktop" ];
      "application/x-tar" = [ "org.kde.ark.desktop" ];
      "application/x-7z-compressed" = [ "org.kde.ark.desktop" ];
      "application/x-rar" = [ "org.kde.ark.desktop" ];
      "application/x-compressed-tar" = [ "org.kde.ark.desktop" ];
      "application/x-bzip-compressed-tar" = [ "org.kde.ark.desktop" ];
      "application/x-xz-compressed-tar" = [ "org.kde.ark.desktop" ];

      # 🎬 Audio & Vidéo -> VLC
      "video/mp4" = [ "vlc.desktop" ];
      "video/mkv" = [ "vlc.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" ];
      "video/webm" = [ "vlc.desktop" ];
      "video/avi" = [ "vlc.desktop" ];
      "video/quicktime" = [ "vlc.desktop" ];
      "audio/mpeg" = [ "vlc.desktop" ];
      "audio/flac" = [ "vlc.desktop" ];
      "audio/wav" = [ "vlc.desktop" ];
      "audio/ogg" = [ "vlc.desktop" ];

      # 🌐 Web -> Zen Browser
      "text/html" = [ "zen-beta.desktop" ];
      "x-scheme-handler/http" = [ "zen-beta.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" ];
    };
  };

  # Configuration Dolphin (Aperçus et vignettes d'images activés par défaut)
  xdg.configFile."dolphinrc".text = ''
    [General]
    BrowseThroughArchives=true
    ShowFullPath=true

    [PreviewSettings]
    Plugins=appimagethumbnail,audiothumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,opendocumentthumbnail,svgthumbnail,textthumbnail,windowsexethumbnail,windowsimagethumbnail,gwenview_raw,gwenview_importer,kdegraphics-thumbnailers,ffmpegthumbs
  '';

  # Patch Remmina pour forcer le clavier AZERTY (Client Keymap)
  # On utilise un script d'activation pour ne pas verrouiller le fichier en lecture seule
  home.activation.patchRemmina = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f $HOME/.config/remmina/remmina.pref ]; then
      run ${pkgs.gnused}/bin/sed -i 's/rdp_use_client_keymap=0/rdp_use_client_keymap=1/' $HOME/.config/remmina/remmina.pref
    fi
  '';

  # Rofi n'est plus utilisé (Plasma/KRunner) : évite l'avertissement de renommage Stylix
  stylix.targets.rofi.enable = false;

  programs.home-manager.enable = true;
}
