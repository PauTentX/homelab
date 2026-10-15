{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Laurent";
        email = "laurent@example.com";
      };
      credential = {
        helper = "store"; # Mémorise identifiant et mot de passe pour ne plus les redemander
      };
    };
  };

  # Configuration de Delta (Coloration avancée pour Git)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
    };
  };
}
