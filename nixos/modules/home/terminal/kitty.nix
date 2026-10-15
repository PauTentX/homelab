{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      scrollback_lines = 10000;
      enable_audio_bell = false;
      window_padding_width = 12;
      shell_integration = "disabled";
      confirm_os_window_close = 0; # Désactive la confirmation à la fermeture
      cursor_shape = "beam";
      cursor_blink_interval = "0.5";
      shell = "${pkgs.fish}/bin/fish";
    };
  };
}
