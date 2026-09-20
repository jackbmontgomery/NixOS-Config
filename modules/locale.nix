{ config, lib, pkgs, ... }:
{
    time.timeZone = "Africa/Johannesburg";
    i18n.defaultLocale = "en_GB.UTF-8";
    console = 
    {
        font = "Lat2-Terminus16";
        useXkbConfig = true;
    };
    services.xserver.xkb.layout = "us";
}
