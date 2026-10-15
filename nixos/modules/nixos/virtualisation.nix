{ config, pkgs, ... }:

{
  # Virtualisation Docker & KVM (requis pour Winboat, conteneurs et machines virtuelles)
  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # Interface graphique Virt-Manager (gestionnaire de machines virtuelles KVM)
  programs.virt-manager.enable = true;
  # Dconf est requis pour que Virt-Manager puisse sauvegarder ses paramètres et connexions
  programs.dconf.enable = true;

  # Dépendances système pour Winboat, KVM et l'exécution d'applications Windows / VM
  environment.systemPackages = with pkgs; [
    docker-compose
    freerdp
    qemu
    virt-viewer
    virtio-win
    win-spice
    spice
    spice-gtk
    spice-protocol
    OVMFFull
    swtpm
    quickemu
    quickgui
  ];

  # Configuration du mode Bridge (Pont réseau) pour les machines virtuelles (Ethernet uniquement)
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp0s31f6" ];
    };
  };
  # Assurer que le pont récupère une IP locale pour que le PC hôte garde internet
  networking.interfaces.br0.useDHCP = true;
  networking.interfaces.enp0s31f6.useDHCP = false;
}
