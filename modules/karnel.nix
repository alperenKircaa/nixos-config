{
  config,
  pkgs,
  ...
}: {
  # NixOS Boot & Kernel Yapılandırma Modülü

  # --- Bootloader ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- SEÇENEK 1: En Güncel Kararlı Çekirdek (Önerilen / Görseldeki) ---
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- SEÇENEK 2: Standart LTS (Long Term Support) Çekirdek ---
  # boot.kernelPackages = pkgs.linuxPackages;

  # --- SEÇENEK 3: Zen Çekirdek (Masaüstü ve Oyun Performansı İçin) ---
  # boot.kernelPackages = pkgs.linuxPackages_zen;

  # --- SEÇENEK 4: XanMod Çekirdek (Yüksek Performans ve Düşük Gecikme) ---
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # --- SEÇENEK 5: Hardened Çekirdek (Ekstra Güvenlik Odaklı) ---
  # boot.kernelPackages = pkgs.linuxPackages_hardened;

  # --- SEÇENEK 6: RT (Real-Time) Çekirdek (Ses Üretimi / Gerçek Zamanlı İşler) ---
  # boot.kernelPackages = pkgs.linuxPackages_rt_latest;
}
