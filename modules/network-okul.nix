{
  config,
  pkgs,
  ...
}: {
  # 1. Okulun sertifikasını sisteme statik ve deklaratif olarak gömüyoruz.
  environment.etc."ssl/certs/wireless.student.bahcesehir.edu.tr.pem".text = ''
    -----BEGIN CERTIFICATE-----
    MIIEMTCCAxmgAwIBAgIQIS8iKoZ7ipxJHe0Jk0839zANBgkqhkiG9w0BAQsFADCB
    izESMBAGCgmSJomT8ixkARkWAnRyMRMwEQYKCZImiZPyLGQBGRYDZWR1MRowGAYK
    CZImiZPyLGQBGRYKYmFoY2VzZWhpcjEXMBUGCgmSJomT8ixkARkWB3N0dWRlbnQx
    KzApBgNVBAMTIndpcmVsZXNzLnN0dWRlbnQuYmFoY2VzZWhpci5lZHUudHIwHhcN
    MjIxMTIxMDg0NDI3WhcNMjcxMTIxMDg1NDI0WjCBizESMBAGCgmSJomT8ixkARkW
    AnRyMRMwEQYKCZImiZPyLGQBGRYDZWR1MRowGAYKCZImiZPyLGQBGRYKYmFoY2Vz
    ZWhpcjEXMBUGCgmSJomT8ixkARkWB3N0dWRlbnQxKzApBgNVBAMTIndpcmVsZXNz
    LnN0dWRlbnQuYmFoY2VzZWhpci5lZHUudHIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
    DwAwggEKAoIBAQCa+T8JvRaNXKcv0b5R3NeNCtDg83rEvopSyl1WQ1Wfg1+BQR6n
    t0cJCQkPPGk0qXuDMDBS86AmP2vmlFecXWVQLNFJgoWz5rPx2W8RKsSmGqjzDaF0
    wBfqyb9AnM4BRFOHykPyUvnjPNv1nSvpmGgIYZSQ3HYXB1Knerrg5bxDdm1NEjkb
    xyCJoP95gajwVxlNV6dj9tx8cpyonSG0+gE2PRnUI/axQ41F+Jt4bLJeWlCLiGt6
    jJXieyummbSCUi6sqWkJBmOwuBPNw6dTipN0gcJGlLMdngiPnFN3FhVinf5DQ1nj
    1AgTSaqba9ywHqdSd2NJuz2/FKCqIcK6bjhzAgMBAAGjgY4wgYswEwYJKwYBBAGC
    NxQCBAYeBABDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0O
    BBYEFGE54dq1zxzzMEjzCoN0LtWC5/kNMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJ
    KwYBBAGCNxUCBBYEFJWlZf5tqpDd9INMpfjd5QHHZ4uJMA0GCSqGSIb3DQEBCwUA
    A4IBAQCBHIJ7y7sy3AGOK4lPkK+p1yhXbvrXfhw8YziWKGFINekyNcXH71EpxCe2
    4Fg1cbogr9rGS895LyEeRSO09YhNjs7P9CtejKCB3IKEV/ItAnpBkP+XQMs729JD
    OS53yHswVKBmcmvxVS8OqBIRB2hIfbHXdne8FckM8ZrmlpkTiiQuVNy3ffjRUMUx
    0RTMy6coROucJ/ET4JzZjDM3kUDxuJTyn1W8NbHfM7paBjkGnCJtiTa6O9pdDO/A
    KO522HxnAwF3UZHerlY/sXBuF/BqD6IRtnQcvihvKlEBQ3lwNZmOjI/BI+pGaQHA
    GkMJlPwWmx4jYsPjyDqNsWviqmEk
    -----END CERTIFICATE-----
  '';

  # 2. Sops Template ile Okul Ağını Tanımlıyoruz (GÜVENLİ VE ÇALIŞAN YÖNTEM)
  sops.templates."Okul-2020.nmconnection" = {
    owner = "root";
    group = "root";
    mode = "0600";
    path = "/etc/NetworkManager/system-connections/Okul-2020.nmconnection";
    content = ''
      [connection]
      id=Okul-2020
      type=wifi
      autoconnect=true

      [wifi]
      ssid=2020
      mode=infrastructure

      [wifi-security]
      key-mgmt=wpa-eap

      [802-1x]
      eap=peap;
      identity=alperen.kirca
      phase2-auth=mschapv2
      password=${config.sops.placeholder.school_wifi_password}
      ca-cert=/etc/ssl/certs/wireless.student.bahcesehir.edu.tr.pem

      [ipv4]
      method=auto

      [ipv6]
      method=auto
    '';
  };

  # 3. Bootloader'da ayrı bir seçenek olarak çıkması için Specialisation
  specialisation."okul-agi".configuration = {
    # Boot menüsünde NixOS - okul-agi şeklinde görünmesini sağlar
    system.nixos.tags = ["okul-agi"];

    # Ağ çökmesini engellemek için NetworkManager arkasında iwd kullanıyoruz
    networking.networkmanager.wifi.backend = "iwd";
  };
}
