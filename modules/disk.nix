# =============================================================================
# Disk Yapılandırması (Disko) — Otomatik Üretildi
# =============================================================================
# Üretim Tarihi: 2026-07-01 17:14
# Kullanıcı: alperenkirca | Hostname: thinkpad
# Disk: /dev/nvme0n1 (SSD)
# Şifreleme: Yok
# Swap: 12G | Boot: 1G
# =============================================================================
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            # 1. EFI BOOT BÖLÜMÜ
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            # 2. BTRFS BÖLÜMÜ (Şifresiz)
            btrfs = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime" "discard=async" "ssd"];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd" "noatime" "discard=async" "ssd"];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime" "discard=async" "ssd"];
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap.swapfile.size = "12G";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
