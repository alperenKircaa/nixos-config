# =============================================================================
# BTRFS Snapshot Yapılandırması (Snapper)
# =============================================================================
# Bu modül, hem / (root) hem de /home dizinleri için otomatik BTRFS
# snapshot'ları oluşturur. Kullanıcı, /home snapshot'larına erişip
# gerektiğinde dosya geri dönüşü yapabilir.
#
# ÖNEMLİ: İlk kurulumdan sonra aşağıdaki komutları bir kez çalıştırın:
#
#   sudo btrfs subvolume create /.snapshots
#   sudo btrfs subvolume create /home/.snapshots
#   sudo chmod 750 /home/.snapshots
#   sudo chown root:users /home/.snapshots
#
# veya kurulum scriptini kullanın:
#   sudo bash /etc/nixos/modules/snapper-init.sh  (bu dosya oluşturulacak)
# =============================================================================
{
  config,
  pkgs,
  username,
  ...
}: {
  # Snapper paketini sisteme ekle (komut satırından kullanmak için)
  environment.systemPackages = with pkgs; [
    snapper
  ];

  services.snapper = {
    snapshotInterval = "hourly"; # Saatlik snapshot timer aralığı
    cleanupInterval = "1d"; # Günlük temizlik timer aralığı

    configs = {
      # ----- ROOT (/) SNAPSHOT YAPILANDIRMASI -----
      root = {
        SUBVOLUME = "/";
        FSTYPE = "btrfs";
        ALLOW_USERS = ["${username}"];

        # Otomatik zamanlama snapshot'ları
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;

        # Saklama politikası (root için daha az tutuyoruz, yer tasarrufu)
        TIMELINE_LIMIT_HOURLY = "5";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "2";
        TIMELINE_LIMIT_MONTHLY = "1";
        TIMELINE_LIMIT_YEARLY = "0";
      };

      # ----- HOME (/home) SNAPSHOT YAPILANDIRMASI -----
      home = {
        SUBVOLUME = "/home";
        FSTYPE = "btrfs";
        ALLOW_USERS = ["${username}"];

        # Otomatik zamanlama snapshot'ları
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;

        # Saklama politikası (home için daha fazla tutuyoruz)
        TIMELINE_LIMIT_HOURLY = "10";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "4";
        TIMELINE_LIMIT_MONTHLY = "6";
        TIMELINE_LIMIT_YEARLY = "1";
      };
    };
  };

  # ============================================================================
  # İlk kurulumda .snapshots subvolume'lerini otomatik oluşturan servis
  # ============================================================================
  # Snapper, snapshot'ları <SUBVOLUME>/.snapshots altına yazar.
  # Bu subvolume yoksa Snapper hata verir. Aşağıdaki oneshot servis,
  # boot sırasında bu dizinleri kontrol edip, yoksa oluşturur.
  # ============================================================================
  systemd.services.snapper-setup = {
    description = "BTRFS .snapshots subvolume'lerini oluştur (Snapper için)";
    wantedBy = ["multi-user.target"];
    before = ["snapper-timeline.timer" "snapper-cleanup.timer"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [pkgs.btrfs-progs pkgs.coreutils];
    script = ''
      # Root (/) için .snapshots subvolume
      if [ ! -d "/.snapshots" ]; then
        echo "/.snapshots subvolume oluşturuluyor..."
        btrfs subvolume create /.snapshots
      fi

      # Home (/home) için .snapshots subvolume
      if [ ! -d "/home/.snapshots" ]; then
        echo "/home/.snapshots subvolume oluşturuluyor..."
        btrfs subvolume create /home/.snapshots
        chmod 750 /home/.snapshots
        chown root:users /home/.snapshots
      fi
    '';
  };
}
