{ config, pkgs, inputs, ... }:

{
  imports = [
    ./boot.nix
    ./hardware.nix
    ./audio.nix
    ./stylix.nix
    ./sddm.nix
    ./plasma.nix
    ./syncthing.nix
    ./samba.nix
    ./virtualisation.nix
    ./users.nix
    ./nix.nix
    ./sops.nix
    ./restic.nix
  ];
}
