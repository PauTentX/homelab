{ config, lib, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /opt/odysseus 0755 root root"
  ];

  systemd.services.odysseus = {
    description = "Odysseus AI Workspace (Docker Compose)";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    requires = [ "docker.service" ];

    path = [ pkgs.docker pkgs.docker-compose pkgs.git ];

    script = ''
      cd /opt/odysseus
      
      # Clone if empty
      if [ ! -d ".git" ]; then
        echo "Cloning Odysseus repository..."
        git clone https://github.com/odysseus-dev/odysseus.git .
      fi
      
      # Create default .env if it doesn't exist to point to local Ollama
      if [ ! -f ".env" ]; then
        echo "Creating default .env file..."
        cat <<EOF > .env
OLLAMA_BASE_URL=http://localhost:11434
LLM_HOST=localhost
AUTH_ENABLED=true
ODYSSEUS_ADMIN_USER=admin
ODYSSEUS_ADMIN_PASSWORD=change_me
# Port d'ecoute
APP_PORT=7000
EOF
      fi

      echo "Starting Docker Compose (this will build the image the first time)..."
      docker-compose up -d --build --remove-orphans
    '';

    preStop = ''
      cd /opt/odysseus
      docker-compose down
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "30min"; # The initial build can take a while
    };
  };
}
