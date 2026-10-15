{ config, pkgs, ... }:

{
  programs.khal = {
    enable = true;
    locale = {
      timeformat = "%H:%M";
      dateformat = "%d/%m/%Y";
      longdateformat = "%d/%m/%Y";
      datetimeformat = "%d/%m/%Y %H:%M";
      longdatetimeformat = "%d/%m/%Y %H:%M";
    };
  };

  programs.vdirsyncer.enable = true;
  services.vdirsyncer.enable = true; # Active le service de synchronisation automatique

  accounts.calendar.basePath = ".calendars";

  accounts.calendar.accounts.nextcloud = {
    khal = {
      enable = true;
      type = "discover";
    };
    
    vdirsyncer = {
      enable = true;
      collections = [ "from a" "from b" ];
      conflictResolution = "remote wins";
    };
    
    remote = {
      type = "caldav";
      url = "https://nextcloud.example.com/remote.php/dav/";
      userName = "user@example.com";
      passwordCommand = [ "cat" "/run/secrets/nextcloud_password" ];
    };
    
    local = {
      type = "filesystem";
      fileExt = ".ics";
    };
  };
}
