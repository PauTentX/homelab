{ config, pkgs, ... }:

{
  # Gestionnaire de connexion SDDM avec thème Astronaut
  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qtdeclarative
      qt5compat
    ];
  };

  # Installation du thème Astronaut avec notre patch maison pour les empreintes digitales
  environment.systemPackages = [
    (pkgs.sddm-astronaut.overrideAttrs (old: {
      installPhase = old.installPhase + ''
        chmod u+w $out/share/sddm/themes/sddm-astronaut-theme/Components/Input.qml
        cp ${./patches/Input.qml} $out/share/sddm/themes/sddm-astronaut-theme/Components/Input.qml
      '';
    }))
  ];

  # Déverrouillage automatique du trousseau KWallet
  security.pam.services.sddm.kwallet.enable = true;
  security.pam.services.login.kwallet.enable = true;
  security.pam.services.kde.kwallet.enable = true;
}
