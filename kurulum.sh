#!/usr/bin/env bash

# Herhangi bir komut hata verirse betiği anında durdur
set -e

# ============================================================================
#  Alperen'in NixOS Otomatik Kurulum Sihirbazı (Dialog TUI)
# ============================================================================
# Bu betik, kullanıcıdan disk tipi, şifreleme tercihi, bölüm boyutları gibi
# bilgileri interaktif olarak alır ve disk.nix dosyasını dinamik olarak üretir.
# ============================================================================

BACKTITLE="Alperen'in NixOS Kurulum Sihirbazı"
CONFIG_DIR="./modules"
DISK_NIX="$CONFIG_DIR/disk.nix"

# ============================================================================
#  Yardımcı Fonksiyonlar
# ============================================================================

hata_ve_cik() {
    dialog --backtitle "$BACKTITLE" \
           --title "❌ HATA" \
           --msgbox "$1" 8 50
    clear
    exit 1
}

bilgi_goster() {
    dialog --backtitle "$BACKTITLE" \
           --title "$1" \
           --msgbox "$2" 10 60
}

ram_miktari_gb() {
    # RAM miktarını GB cinsinden döndür (yukarı yuvarla)
    local ram_kb
    ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $(( (ram_kb + 1048575) / 1048576 ))
}

# ============================================================================
#  Dialog kontrolü
# ============================================================================

if ! command -v dialog &> /dev/null; then
    echo "HATA: 'dialog' paketi bulunamadı!"
    echo "NixOS ISO'ya eklenmiş olmalı. Manuel kurulum için:"
    echo "  nix-env -iA nixos.dialog"
    exit 1
fi

# ============================================================================
#  [0/6] HOŞGELDİN EKRANI
# ============================================================================

dialog --backtitle "$BACKTITLE" \
       --title "🚀 NixOS Kurulum Sihirbazı" \
       --yes-label "Başla" \
       --no-label "Çıkış" \
       --yesno "\
Alperen'in NixOS Otomatik Kurulum Sihirbazına hoş geldin!

Bu sihirbaz sana aşağıdaki soruları soracak:

  • Hangi diske kurulsun?
  • Disk tipi: SSD mi, HDD mi?
  • LUKS disk şifreleme istiyor musun?
  • Swap alanı ne kadar olsun?
  • Boot bölümü boyutu
  • Bilgisayarın hostname'i

Ardından disk.nix otomatik oluşturulacak ve
NixOS kurulumu başlayacak.

Devam etmek istiyor musun?" 20 56

if [ $? -ne 0 ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

# ============================================================================
#  [1/6] SSH ANAHTARI KONTROLÜ
# ============================================================================

SSH_KEY="$HOME/.ssh/id_ed25519"

if [ ! -f "$SSH_KEY" ]; then
    dialog --backtitle "$BACKTITLE" \
           --title "🔑 SSH Anahtarı Gerekli" \
           --msgbox "\
SSH Private Key (~/.ssh/id_ed25519) bulunamadı!

Bir sonraki ekranda id_ed25519 (Private Key)
içeriğini yapıştırman gerekecek." 10 55

    # Dialog editbox ile key alma
    TEMP_KEY=$(mktemp)
    dialog --backtitle "$BACKTITLE" \
           --title "🔑 SSH Private Key Girişi" \
           --inputbox "id_ed25519 private key içeriğini yapıştır ve OK'e bas.\n(Alternatif: Bu ekranı iptal et, key'i manuel kopyala, scripti tekrar çalıştır)" \
           12 70 2>"$TEMP_KEY"

    if [ $? -ne 0 ] || [ ! -s "$TEMP_KEY" ]; then
        rm -f "$TEMP_KEY"
        hata_ve_cik "SSH anahtarı alınamadı. Kurulum iptal edildi."
    fi

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    mv "$TEMP_KEY" "$SSH_KEY"
    chmod 600 "$SSH_KEY"

    # Anahtarın geçerli olup olmadığını kontrol et
    if ! ssh-keygen -l -f "$SSH_KEY" > /dev/null 2>&1; then
        rm -f "$SSH_KEY"
        hata_ve_cik "Geçersiz veya bozuk SSH anahtarı! Kurulum durduruldu."
    fi

    bilgi_goster "✅ SSH Anahtarı" "Anahtar başarıyla doğrulandı ve kaydedildi."
fi

# SSH Key yetki kontrolü
chmod 600 "$SSH_KEY"

# ============================================================================
#  [2/6] DİSK SEÇİMİ
# ============================================================================

# Mevcut diskleri listele (sadece disk tipindekiler, partition değil)
DISK_LIST=()
while IFS= read -r line; do
    disk_name=$(echo "$line" | awk '{print $1}')
    disk_size=$(echo "$line" | awk '{print $2}')
    disk_type=$(echo "$line" | awk '{print $3}')
    disk_tran=$(echo "$line" | awk '{print $4}')

    # Transport bilgisi varsa ekle
    if [ -n "$disk_tran" ]; then
        disk_label="$disk_size ($disk_tran)"
    else
        disk_label="$disk_size"
    fi

    DISK_LIST+=("/dev/$disk_name" "$disk_label")
done < <(lsblk -dnpo NAME,SIZE,TYPE,TRAN | grep "disk" | grep -v "loop")

if [ ${#DISK_LIST[@]} -eq 0 ]; then
    hata_ve_cik "Sistemde hiç disk bulunamadı!"
fi

SECILEN_DISK=$(dialog --backtitle "$BACKTITLE" \
                      --title "💾 Disk Seçimi [1/6]" \
                      --menu "\nKurulum yapılacak diski seç:\n\n⚠️  SEÇİLEN DİSK TAMAMEN SİLİNECEKTİR!" \
                      18 60 6 \
                      "${DISK_LIST[@]}" \
                      3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

# ============================================================================
#  [3/6] DİSK TİPİ (SSD / HDD)
# ============================================================================

# Otomatik tespit dene (rotational = 0 ise SSD)
DISK_BASENAME=$(basename "$SECILEN_DISK")
# NVMe diskler için parent device adını al
if [[ "$DISK_BASENAME" == nvme* ]]; then
    ROTATIONAL_PATH="/sys/block/$DISK_BASENAME/queue/rotational"
else
    ROTATIONAL_PATH="/sys/block/$DISK_BASENAME/queue/rotational"
fi

OTOMATIK_TIP="Bilinmiyor"
if [ -f "$ROTATIONAL_PATH" ]; then
    ROT=$(cat "$ROTATIONAL_PATH")
    if [ "$ROT" -eq 0 ]; then
        OTOMATIK_TIP="SSD"
    else
        OTOMATIK_TIP="HDD"
    fi
fi

DISK_TIPI=$(dialog --backtitle "$BACKTITLE" \
                   --title "⚡ Disk Tipi [2/6]" \
                   --default-item "$OTOMATIK_TIP" \
                   --menu "\nDisk tipi nedir?\n\nOtomatik tespit: $OTOMATIK_TIP\n\nSSD → TRIM, discard=async aktif\nHDD → autodefrag aktif" \
                   16 55 3 \
                   "SSD" "Solid State Drive (TRIM + discard)" \
                   "HDD" "Hard Disk Drive (autodefrag)" \
                   3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

# ============================================================================
#  [4/6] LUKS ŞİFRELEME
# ============================================================================

dialog --backtitle "$BACKTITLE" \
       --title "🔒 Disk Şifreleme (LUKS) [3/6]" \
       --yes-label "Evet, Şifrele" \
       --no-label "Hayır" \
       --yesno "\
LUKS disk şifreleme aktif edilsin mi?

LUKS Açık:
  ✓ Tüm veriler şifrelenir
  ✓ Bilgisayar çalınsa bile veri güvende
  ✗ Boot'ta şifre girmen gerekir
  ✗ Çok küçük performans kaybı

LUKS Kapalı:
  ✓ Doğrudan boot, şifre yok
  ✓ Biraz daha hızlı I/O
  ✗ Fiziksel erişimde veri korumasız" 18 55

LUKS_AKTIF=$?
# 0 = Evet, 1 = Hayır

# ============================================================================
#  [5/6] SWAP BOYUTU
# ============================================================================

RAM_GB=$(ram_miktari_gb)
ONERILEN_SWAP="${RAM_GB}G"

SWAP_SECIM=$(dialog --backtitle "$BACKTITLE" \
                    --title "💤 Swap Boyutu [4/6]" \
                    --default-item "auto" \
                    --menu "\nSwap alanı ne kadar olsun?\n\nSisteminde $RAM_GB GB RAM tespit edildi.\nÖnerilen: ${ONERILEN_SWAP} (RAM kadar)" \
                    16 55 4 \
                    "auto"   "${ONERILEN_SWAP} (RAM kadar — önerilen)" \
                    "half"   "$(( RAM_GB / 2 ))G (RAM'in yarısı)" \
                    "double" "$(( RAM_GB * 2 ))G (RAM'in 2 katı — hibernate)" \
                    "custom" "Manuel giriş" \
                    3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

case "$SWAP_SECIM" in
    auto)   SWAP_BOYUT="${RAM_GB}G" ;;
    half)   SWAP_BOYUT="$(( RAM_GB / 2 ))G" ;;
    double) SWAP_BOYUT="$(( RAM_GB * 2 ))G" ;;
    custom)
        SWAP_BOYUT=$(dialog --backtitle "$BACKTITLE" \
                            --title "Swap Boyutu (Manuel)" \
                            --inputbox "Swap boyutunu gir (örn: 4G, 16G):" \
                            8 45 "${ONERILEN_SWAP}" \
                            3>&1 1>&2 2>&3)
        if [ $? -ne 0 ] || [ -z "$SWAP_BOYUT" ]; then
            SWAP_BOYUT="$ONERILEN_SWAP"
        fi
        ;;
esac

# ============================================================================
#  [5.5/6] BOOT BÖLÜMÜ BOYUTU
# ============================================================================

BOOT_BOYUT=$(dialog --backtitle "$BACKTITLE" \
                    --title "🥾 Boot Bölümü [5/6]" \
                    --default-item "512M" \
                    --menu "\nEFI boot bölümü boyutu:" \
                    12 50 3 \
                    "512M"  "Standart (önerilen)" \
                    "1G"    "Büyük (çoklu kernel)" \
                    3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

# ============================================================================
#  [6/6] HOSTNAME
# ============================================================================

HOSTNAME=$(dialog --backtitle "$BACKTITLE" \
                  --title "🏷️  Hostname [6/6]" \
                  --inputbox "\nBilgisayarın ağdaki adı ne olsun?" \
                  9 50 "thinkpad" \
                  3>&1 1>&2 2>&3)

if [ $? -ne 0 ] || [ -z "$HOSTNAME" ]; then
    HOSTNAME="thinkpad"
fi

# ============================================================================
#  ÖZET ve ONAY
# ============================================================================

if [ "$LUKS_AKTIF" -eq 0 ]; then
    LUKS_DURUM="✅ AÇIK (şifreli)"
else
    LUKS_DURUM="❌ KAPALI (şifresiz)"
fi

dialog --backtitle "$BACKTITLE" \
       --title "📋 Kurulum Özeti" \
       --yes-label "KUR" \
       --no-label "İptal" \
       --yesno "\
Aşağıdaki ayarlarla kurulum yapılacak:

  Disk:        $SECILEN_DISK
  Disk Tipi:   $DISK_TIPI
  Şifreleme:   $LUKS_DURUM
  Swap:        $SWAP_BOYUT
  Boot:        $BOOT_BOYUT
  Hostname:    $HOSTNAME
  Dosya Sist.: BTRFS (zstd sıkıştırma)

⚠️  $SECILEN_DISK DİSKİ TAMAMEN SİLİNECEKTİR!

Devam edilsin mi?" 20 55

if [ $? -ne 0 ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

# ============================================================================
#  disk.nix ÜRET
# ============================================================================

clear
echo ""
echo "======================================================="
echo "[1/5] disk.nix oluşturuluyor..."
echo "======================================================="

# Mount seçeneklerini belirle
if [ "$DISK_TIPI" = "SSD" ]; then
    MOUNT_OPTS='"compress=zstd" "noatime" "discard=async" "ssd"'
    TRIM_AYAR="true"
else
    MOUNT_OPTS='"compress=zstd" "noatime" "autodefrag"'
    TRIM_AYAR="false"
fi

# disk.nix dosyasını oluştur
if [ "$LUKS_AKTIF" -eq 0 ]; then
    # ===== LUKS AÇIK =====
    cat > "$DISK_NIX" << NIXEOF
# =============================================================================
# Disk Yapılandırması (Disko) — Otomatik Üretildi
# =============================================================================
# Üretim Tarihi: $(date '+%Y-%m-%d %H:%M')
# Disk: $SECILEN_DISK ($DISK_TIPI)
# Şifreleme: LUKS
# Swap: $SWAP_BOYUT | Boot: $BOOT_BOYUT
# =============================================================================
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "$SECILEN_DISK";
        content = {
          type = "gpt";
          partitions = {
            # 1. EFI BOOT BÖLÜMÜ
            ESP = {
              size = "$BOOT_BOYUT";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            # 2. LUKS + BTRFS BÖLÜMÜ
            luks-btrfs = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted-root";
                settings.allowDiscards = $TRIM_AYAR;

                content = {
                  type = "btrfs";
                  extraArgs = ["-f"];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [$MOUNT_OPTS];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [$MOUNT_OPTS];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [$MOUNT_OPTS];
                    };
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "$SWAP_BOYUT";
                    };
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
NIXEOF
else
    # ===== LUKS KAPALI =====
    cat > "$DISK_NIX" << NIXEOF
# =============================================================================
# Disk Yapılandırması (Disko) — Otomatik Üretildi
# =============================================================================
# Üretim Tarihi: $(date '+%Y-%m-%d %H:%M')
# Disk: $SECILEN_DISK ($DISK_TIPI)
# Şifreleme: Yok
# Swap: $SWAP_BOYUT | Boot: $BOOT_BOYUT
# =============================================================================
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "$SECILEN_DISK";
        content = {
          type = "gpt";
          partitions = {
            # 1. EFI BOOT BÖLÜMÜ
            ESP = {
              size = "$BOOT_BOYUT";
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
                    mountOptions = [$MOUNT_OPTS];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [$MOUNT_OPTS];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [$MOUNT_OPTS];
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap.swapfile.size = "$SWAP_BOYUT";
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
NIXEOF
fi

echo "✅ disk.nix oluşturuldu: $DISK_NIX"
echo ""

# Hostname'i network.nix'e yaz
echo "======================================================="
echo "    Hostname güncelleniyor: $HOSTNAME"
echo "======================================================="
sed -i "s/networking.hostName = \".*\"/networking.hostName = \"$HOSTNAME\"/" "$CONFIG_DIR/network.nix"
echo "✅ Hostname güncellendi."
echo ""

# SSD ise fstrim'i kontrol et, HDD ise kapat
if [ "$DISK_TIPI" = "HDD" ]; then
    echo "ℹ️  HDD tespit edildi — fstrim gerekli değil."
fi

# ============================================================================
#  [2/5] Disko ile disk bölümleme
# ============================================================================

echo ""
echo "======================================================="
echo "[2/5] Disko ile diskler bölümleniyor..."
echo "======================================================="
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko --flake .#thinkpad

# ============================================================================
#  [3/5] SSH Anahtarlarını kopyala
# ============================================================================

echo ""
echo "======================================================="
echo "[3/5] SSH Anahtarları yeni sisteme kopyalanıyor..."
echo "======================================================="
# Kullanıcı klasörü ve SSH klasörlerini oluştur
sudo mkdir -p /mnt/home/alperenkirca/.ssh
sudo mkdir -p /mnt/etc/ssh

# Private Key'i kullanıcı klasörüne kopyala
sudo cp "$SSH_KEY" /mnt/home/alperenkirca/.ssh/id_ed25519
sudo chmod 600 /mnt/home/alperenkirca/.ssh/id_ed25519

# Public Key'i oluştur
ssh-keygen -y -f "$SSH_KEY" | sudo tee /mnt/home/alperenkirca/.ssh/id_ed25519.pub > /dev/null
sudo chmod 644 /mnt/home/alperenkirca/.ssh/id_ed25519.pub

# Aynı key'i sistem (Host) key'i olarak kopyala (sops-nix için)
sudo cp "$SSH_KEY" /mnt/etc/ssh/ssh_host_ed25519_key
sudo chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
ssh-keygen -y -f "$SSH_KEY" | sudo tee /mnt/etc/ssh/ssh_host_ed25519_key.pub > /dev/null
sudo chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub

# ============================================================================
#  [4/5] NixOS Kurulumu
# ============================================================================

echo ""
echo "======================================================="
echo "[4/5] NixOS sistemi kuruluyor..."
echo "======================================================="
sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-install --flake .#thinkpad

# ============================================================================
#  [5/5] Konfigürasyon dosyalarını kopyala
# ============================================================================

echo ""
echo "======================================================="
echo "[5/5] Konfigürasyon dosyaları ~/nixos-config'e kopyalanıyor..."
echo "======================================================="
sudo mkdir -p /mnt/home/alperenkirca/nixos-config
sudo cp -r . /mnt/home/alperenkirca/nixos-config
# Yetkileri kullanıcıya ver
sudo chown -R 1000:100 /mnt/home/alperenkirca/nixos-config
sudo chown -R 1000:100 /mnt/home/alperenkirca/.ssh

echo ""
echo "======================================================="
echo " KURULUM BAŞARIYLA TAMAMLANDI! 🎉"
echo "======================================================="
echo "  Disk:      $SECILEN_DISK ($DISK_TIPI)"
echo "  Şifreleme: $LUKS_DURUM"
echo "  Swap:      $SWAP_BOYUT"
echo "  Hostname:  $HOSTNAME"
echo "-------------------------------------------------------"
echo "1. Sistemi yeniden başlat: reboot"
echo "2. Yeni sistemde ~/nixos-config klasörüne gir."
echo "3. Kurulum sonrası betiğini çalıştır: ./indirmesonrasi.sh"
echo "======================================================="
