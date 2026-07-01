{
  config,
  pkgs,
  ...
}: {
  networking.hostName = "thinkpad";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    # LocalSend - cihaz keşfi ve dosya transferi için
    allowedTCPPorts = [53317];
    allowedUDPPorts = [53317];
    # VPN ağ arayüzünü sistem genelinde güvenilir yapıyoruz.
    # Eğer resmi Proton app kullanıyorsan genelde 'proton0' olur.
    # WireGuard kullanıyorsan 'wg0' veya 'tun0' olabilir.
    trustedInterfaces = ["proton0"];
  };
}
