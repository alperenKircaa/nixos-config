{config, ...}: {
  sops.templates."TurkNet.nmconnection" = {
    owner = "root";
    group = "root";
    mode = "0600";
    path = "/etc/NetworkManager/system-connections/TurkNet.nmconnection";
    content = ''
      [connection]
      id=TurkNet1000Mbps_1231E
      type=wifi
      autoconnect=true

      [wifi]
      ssid=TurkNet1000Mbps_1231E
      mode=infrastructure

      [wifi-security]
      auth-alg=open
      key-mgmt=wpa-psk
      psk=${config.sops.placeholder.home_wifi_password}

      [ipv4]
      method=auto

      [ipv6]
      method=auto
      addr-gen-mode=stable-privacy
    '';
  };
}
