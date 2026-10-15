{ config, pkgs, lib, ... }:

{
  # ==========================================
  # 1. OPTIMISATION MATÉRIELLE (NVIDIA + KERNEL)
  # ==========================================
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  # ==========================================
  # 2. PLAN DE DISQUES DÉCLARATIF (XFS + RAID0)
  # ==========================================
  boot.swraid.enable = true;
  # Évite le crash de mdmon (aucun mail configuré) : on déclare un PROGRAM no-op
  boot.swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";

  disko.devices = {
    disk = {
      nvme1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            swap = {
              size = "32G";
              content = { type = "swap"; randomEncryption = true; };
            };
            raid = {
              size = "100%";
              content = { type = "mdraid"; name = "ia_raid"; };
            };
          };
        };
      };
      nvme2 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            swap = {
              size = "32G";
              content = { type = "swap"; randomEncryption = true; };
            };
            raid = {
              size = "100%";
              content = { type = "mdraid"; name = "ia_raid"; };
            };
          };
        };
      };
    };
    mdadm = {
      ia_raid = {
        type = "mdadm";
        level = 0;
        content = {
          type = "filesystem";
          format = "xfs";
          mountpoint = "/var/lib/ollama";
          extraArgs = [ "-L" "OLLAMA_XFS" ];
        };
      };
    };
  };

  # ==========================================
  # 3. AUTO-RÉPARATION
  # ==========================================
  fileSystems."/var/lib/ollama".options = [ "nofail" ];

  systemd.services.disko-auto-repair = {
    description = "Formate les NVMe s'ils ont été effacés par le LanCache";
    wantedBy = [ "multi-user.target" ];
    before = [ "ollama.service" ];
    path = with pkgs; [ util-linux mdadm ];
    serviceConfig.Type = "oneshot";
    script = ''
      if ! blkid -L OLLAMA_XFS >/dev/null 2>&1; then
        echo "Disques NVMe effacés ! Re-création du RAID0 et formatage XFS..."
        ${config.system.build.diskoScript}
        chown -R ollama:ollama /var/lib/ollama
      fi
    '';
  };

  # ==========================================
  # 4. MOTEUR IA & AUTO-TÉLÉCHARGEMENT DIRECT SUR NVME
  # ==========================================
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda; # remplace services.ollama.acceleration (supprimé de nixpkgs)
    host = "0.0.0.0";
    port = 11434;
  };
  networking.firewall.allowedTCPPorts = [ 11434 ];

  systemd.services.ollama-auto-pull = {
    description = "Téléchargement automatique des modèles manquants sur les NVMe";
    wantedBy = [ "multi-user.target" ];
    after = [ "ollama.service" ];
    path = [ config.services.ollama.package pkgs.curl pkgs.jq ];
    script = ''
      until curl -s http://127.0.0.1:11434/api/tags > /dev/null; do sleep 2; done
      
      # VOS MODÈLES À GARDER EN PERMANENCE
      models=("qwen2.5:7b" "mistral-nemo:12b" "qwen2.5:32b")
      
      for model in "''${models[@]}"; do
        if ! curl -s http://127.0.0.1:11434/api/tags | jq -e ".models[] | select(.name == \"$model\")" > /dev/null; then
          echo "Téléchargement du modèle manquant : $model..."
          ollama pull $model
        fi
      done
    '';
  };

  environment.systemPackages = with pkgs; [ nvtopPackages.nvidia htop btop jq curl ];
}
