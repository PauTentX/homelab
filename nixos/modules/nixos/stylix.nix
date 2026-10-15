{ config, pkgs, ... }:

{
  # Gestionnaire de thème universel automatique Stylix
  stylix = {
    enable = true;

    # Fond d'écran par défaut (issu du dossier local Wallpapers)
    image = ../../Wallpapers/pixelart_night_train_cozy_gas_RoyalNaym.png;

    # Palette de couleurs (Catppuccin Mocha)
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";

    # Opacité translucide gérée par Stylix
    opacity = {
      terminal = 0.88;
      applications = 0.95;
      popups = 0.90;
      desktop = 1.0;
    };

    # Curseur de souris moderne Bibata
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Polices système style macOS (Inter pour l'UI, Meslo pour le terminal et code)
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.meslo-lg;
        name = "MesloLGS Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sizes = {
        applications = 11;
        terminal = 13;
        desktop = 10;
        popups = 10;
      };
    };
  };
}
