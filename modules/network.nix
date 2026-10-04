{
  config,
  lib,
  pkgs,
  ...
}: let
  uctEap = {
    eap = "peap;";
    identity = "mntjac003@wf.uct.ac.za";
    phase2-auth = "mschapv2";
    ca-cert = "${../uct-eduroam-ca.pem}";
    domain-match = "*.uct.ac.za;nac.uct.ac.za";
    password = "$EDUROAM_PASSWORD";
  };
in {
  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
    logLevel = "INFO";

    ensureProfiles.environmentFiles = ["/etc/nixos/secrets/eduroam.env"];

    ensureProfiles.profiles = {
      eduroam = {
        connection = {
          id = "eduroam";
          type = "wifi";
          interface-name = "wlp3s0";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "eduroam";
        };
        wifi-security = {
          key-mgmt = "wpa-eap";
          proto = "rsn;";
          pairwise = "ccmp;";
          group = "ccmp;";
        };
        "802-1x" = uctEap;
        ipv4.method = "auto";
        ipv6.method = "auto";
      };

      wired-eduroam = {
        connection = {
          id = "wired-eduroam";
          type = "ethernet";
          autoconnect-priority = 100;
          autoconnect-retries = 3;
        };
        "802-1x" =
          uctEap
          // {
            optional = false;
            auth-timeout = 10;
          };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;
}
