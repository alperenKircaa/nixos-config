#!/usr/bin/env bash

# Herhangi bir komut hata verirse betiği anında durdur
set -e

# ============================================================================
#  NixOS Otomatik Kurulum Sihirbazı (Dialog TUI)
# ============================================================================
# Bu betik, kullanıcıdan kullanıcı adı, disk tipi, şifreleme tercihi, bölüm
# boyutları gibi bilgileri interaktif olarak alır ve disk.nix dosyasını
# dinamik olarak üretir. Herkes kendi ayarlarıyla kullanabilir.
# ============================================================================

BACKTITLE="NixOS Kurulum Sihirbazı"
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
#  [0/8] HOŞGELDİN EKRANI
# ============================================================================

dialog --backtitle "$BACKTITLE" \
       --title "🚀 NixOS Kurulum Sihirbazı" \
       --yes-label "Başla" \
       --no-label "Çıkış" \
       --yesno "\
NixOS Otomatik Kurulum Sihirbazına hoş geldin!

Bu sihirbaz sana aşağıdaki soruları soracak:

  • Kullanıcı adı ve hostname
  • Hangi diske kurulsun?
  • Disk tipi: SSD mi, HDD mi?
  • LUKS disk şifreleme istiyor musun?
  • Swap alanı ne kadar olsun?
  • Boot bölümü boyutu

Ardından tüm config dosyaları otomatik
güncellenecek ve NixOS kurulumu başlayacak.

Devam etmek istiyor musun?" 21 56

if [ $? -ne 0 ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

# ============================================================================
#  [1/8] KULLANICI ADI
# ============================================================================

KULLANICI=$(dialog --backtitle "$BACKTITLE" \
                   --title "👤 Kullanıcı Adı [1/8]" \
                   --inputbox "\
Sisteme giriş yapacak kullanıcı adını gir.

Kurallar:
  • Küçük harf, rakam ve tire (-) kullanılabilir
  • Boşluk ve özel karakter kullanılamaz
  • Örnek: alperen, mehmet, nixuser" \
                   15 55 "" \
                   3>&1 1>&2 2>&3)

if [ $? -ne 0 ] || [ -z "$KULLANICI" ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

# Kullanıcı adı validasyonu
if ! echo "$KULLANICI" | grep -qE '^[a-z][a-z0-9_-]*$'; then
    hata_ve_cik "Geçersiz kullanıcı adı: '$KULLANICI'\n\nKüçük harfle başlamalı, sadece küçük harf,\nrakam, tire (-) ve alt çizgi (_) içerebilir."
fi

# ============================================================================
#  [2/8] SSH ANAHTARI
# ============================================================================

SSH_KEY="$HOME/.ssh/id_ed25519"

if [ -f "$SSH_KEY" ]; then
    # Key zaten var — kullanıcıya bilgi ver
    KEY_PARMAK=$(ssh-keygen -l -f "$SSH_KEY" 2>/dev/null | awk '{print $2}')
    dialog --backtitle "$BACKTITLE" \
           --title "🔑 SSH Anahtarı [2/8]" \
           --yes-label "Kullan" \
           --no-label "Değiştir" \
           --yesno "\
Mevcut SSH anahtarı bulundu:

  📁 $SSH_KEY
  🔑 $KEY_PARMAK

Bu anahtarı kullanmak istiyor musun?" 12 58

    if [ $? -ne 0 ]; then
        # Kullanıcı değiştirmek istiyor — mevcut key'i yedekle
        mv "$SSH_KEY" "${SSH_KEY}.yedek.$(date +%s)"
        [ -f "${SSH_KEY}.pub" ] && mv "${SSH_KEY}.pub" "${SSH_KEY}.pub.yedek.$(date +%s)"
    fi
fi

if [ ! -f "$SSH_KEY" ]; then
    SSH_SECIM=$(dialog --backtitle "$BACKTITLE" \
                       --title "🔑 SSH Anahtarı [2/8]" \
                       --menu "\
SSH Private Key bulunamadı.
Ne yapmak istersin?" \
                       14 58 3 \
                       "olustur" "🆕 Yeni SSH anahtarı oluştur (önerilen)" \
                       "yapistir" "📋 Var olan key'i yapıştır" \
                       "iptal"   "❌ Kurulumu iptal et" \
                       3>&1 1>&2 2>&3)

    if [ $? -ne 0 ] || [ "$SSH_SECIM" = "iptal" ]; then
        clear
        echo "Kurulum iptal edildi."
        exit 0
    fi

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    case "$SSH_SECIM" in
        olustur)
            # E-posta sor (key comment olarak)
            SSH_EMAIL=$(dialog --backtitle "$BACKTITLE" \
                               --title "🆕 Yeni SSH Key Oluştur" \
                               --inputbox "\
SSH anahtarına eklenecek e-posta adresini gir.
(Opsiyonel — boş bırakabilirsin)" \
                               10 55 "${KULLANICI}@nixos" \
                               3>&1 1>&2 2>&3)

            [ $? -ne 0 ] && SSH_EMAIL="${KULLANICI}@nixos"
            [ -z "$SSH_EMAIL" ] && SSH_EMAIL="${KULLANICI}@nixos"

            # Key oluştur (parola korumasız — kurulum ortamı)
            ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" -N "" > /dev/null 2>&1

            if [ ! -f "$SSH_KEY" ]; then
                hata_ve_cik "SSH anahtarı oluşturulamadı!"
            fi

            KEY_PARMAK=$(ssh-keygen -l -f "$SSH_KEY" 2>/dev/null | awk '{print $2}')
            bilgi_goster "✅ SSH Anahtarı Oluşturuldu" "\
Yeni anahtar başarıyla oluşturuldu!

  📁 $SSH_KEY
  🔑 $KEY_PARMAK
  📧 $SSH_EMAIL

⚠️  Kurulum bittikten sonra public key'ini
GitHub/GitLab'a eklemeyi unutma!"
            ;;

        yapistir)
            dialog --backtitle "$BACKTITLE" \
                   --title "📋 SSH Key Yapıştır" \
                   --msgbox "\
Bir sonraki ekranda id_ed25519 (Private Key)
içeriğini yapıştırman gerekecek.

Alternatif: Scripti iptal et, key dosyasını
~/.ssh/id_ed25519 konumuna kopyala, tekrar çalıştır." 12 58

            TEMP_KEY=$(mktemp)
            dialog --backtitle "$BACKTITLE" \
                   --title "📋 SSH Private Key Girişi" \
                   --inputbox "id_ed25519 private key içeriğini yapıştır:" \
                   12 70 2>"$TEMP_KEY"

            if [ $? -ne 0 ] || [ ! -s "$TEMP_KEY" ]; then
                rm -f "$TEMP_KEY"
                hata_ve_cik "SSH anahtarı alınamadı. Kurulum iptal edildi."
            fi

            mv "$TEMP_KEY" "$SSH_KEY"
            chmod 600 "$SSH_KEY"

            # Doğrulama
            if ! ssh-keygen -l -f "$SSH_KEY" > /dev/null 2>&1; then
                rm -f "$SSH_KEY"
                hata_ve_cik "Geçersiz veya bozuk SSH anahtarı! Kurulum durduruldu."
            fi

            bilgi_goster "✅ SSH Anahtarı" "Anahtar başarıyla doğrulandı ve kaydedildi."
            ;;
    esac
fi

# SSH Key yetki kontrolü
chmod 600 "$SSH_KEY"

# Public key'i oluştur/oku
SSH_PUB_KEY=$(ssh-keygen -y -f "$SSH_KEY" 2>/dev/null)
if [ -z "$SSH_PUB_KEY" ]; then
    hata_ve_cik "SSH public key oluşturulamadı!"
fi

# ============================================================================
#  [3/8] DİSK SEÇİMİ
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
                      --title "💾 Disk Seçimi [3/8]" \
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
#  [4/8] DİSK TİPİ (SSD / HDD)
# ============================================================================

# Otomatik tespit dene (rotational = 0 ise SSD)
DISK_BASENAME=$(basename "$SECILEN_DISK")
ROTATIONAL_PATH="/sys/block/$DISK_BASENAME/queue/rotational"

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
                   --title "⚡ Disk Tipi [4/8]" \
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
#  [5/8] LUKS ŞİFRELEME
# ============================================================================

dialog --backtitle "$BACKTITLE" \
       --title "🔒 Disk Şifreleme (LUKS) [5/8]" \
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
#  [6/8] SWAP BOYUTU
# ============================================================================

RAM_GB=$(ram_miktari_gb)
ONERILEN_SWAP="${RAM_GB}G"

SWAP_SECIM=$(dialog --backtitle "$BACKTITLE" \
                    --title "💤 Swap Boyutu [6/8]" \
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
#  [7/8] BOOT BÖLÜMÜ BOYUTU
# ============================================================================

BOOT_BOYUT=$(dialog --backtitle "$BACKTITLE" \
                    --title "🥾 Boot Bölümü [7/8]" \
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
#  [8/8] HOSTNAME
# ============================================================================

HOSTNAME=$(dialog --backtitle "$BACKTITLE" \
                  --title "🏷️  Hostname [8/8]" \
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

  Kullanıcı:   $KULLANICI
  Hostname:    $HOSTNAME
  Disk:        $SECILEN_DISK
  Disk Tipi:   $DISK_TIPI
  Şifreleme:   $LUKS_DURUM
  Swap:        $SWAP_BOYUT
  Boot:        $BOOT_BOYUT
  Dosya Sist.: BTRFS (zstd sıkıştırma)

⚠️  $SECILEN_DISK DİSKİ TAMAMEN SİLİNECEKTİR!

Devam edilsin mi?" 21 55

if [ $? -ne 0 ]; then
    clear
    echo "Kurulum iptal edildi."
    exit 0
fi

# ============================================================================
#  KONFIGÜRASYON DOSYALARINI GÜNCELLE
# ============================================================================

clear
echo ""
echo "======================================================="
echo "[1/6] Konfigürasyon dosyaları güncelleniyor..."
echo "======================================================="

# --- disk.nix üret ---
echo "  → disk.nix oluşturuluyor..."

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
# Kullanıcı: $KULLANICI | Hostname: $HOSTNAME
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
# Kullanıcı: $KULLANICI | Hostname: $HOSTNAME
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

echo "  ✅ disk.nix oluşturuldu"

# --- flake.nix: username güncelle ---
echo "  → flake.nix güncelleniyor (username = \"$KULLANICI\")..."
sed -i "s/username = \".*\"/username = \"$KULLANICI\"/" ./flake.nix
echo "  ✅ flake.nix güncellendi"

# --- network.nix: hostname güncelle ---
echo "  → network.nix güncelleniyor (hostname = \"$HOSTNAME\")..."
sed -i "s/networking.hostName = \".*\"/networking.hostName = \"$HOSTNAME\"/" "$CONFIG_DIR/network.nix"
echo "  ✅ network.nix güncellendi"

# --- flake.nix: nixosConfigurations adını hostname ile eşleştir ---
# "thinkpad" olan config adını hostname'le değiştir
echo "  → flake.nix config adı güncelleniyor ($HOSTNAME)..."
sed -i "s/^      thinkpad = nixpkgs/      $HOSTNAME = nixpkgs/" ./flake.nix
echo "  ✅ Config adı güncellendi"

echo ""
echo "✅ Tüm konfigürasyon dosyaları güncellendi."
echo ""

# ============================================================================
#  [2/6] Disko ile disk bölümleme
# ============================================================================

echo ""
echo "======================================================="
echo "[2/6] Disko ile diskler bölümleniyor..."
echo "======================================================="
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko --flake ".#$HOSTNAME"

# ============================================================================
#  [3/6] SSH Anahtarlarını kopyala
# ============================================================================

echo ""
echo "======================================================="
echo "[3/6] SSH Anahtarları yeni sisteme kopyalanıyor..."
echo "======================================================="
# Kullanıcı klasörü ve SSH klasörlerini oluştur
sudo mkdir -p "/mnt/home/$KULLANICI/.ssh"
sudo mkdir -p /mnt/etc/ssh

# Private Key'i kullanıcı klasörüne kopyala
sudo cp "$SSH_KEY" "/mnt/home/$KULLANICI/.ssh/id_ed25519"
sudo chmod 600 "/mnt/home/$KULLANICI/.ssh/id_ed25519"

# Public Key'i oluştur
echo "$SSH_PUB_KEY" | sudo tee "/mnt/home/$KULLANICI/.ssh/id_ed25519.pub" > /dev/null
sudo chmod 644 "/mnt/home/$KULLANICI/.ssh/id_ed25519.pub"

# Aynı key'i sistem (Host) key'i olarak kopyala (sops-nix için)
sudo cp "$SSH_KEY" /mnt/etc/ssh/ssh_host_ed25519_key
sudo chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
echo "$SSH_PUB_KEY" | sudo tee /mnt/etc/ssh/ssh_host_ed25519_key.pub > /dev/null
sudo chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub

# ============================================================================
#  [4/6] NixOS Kurulumu
# ============================================================================

echo ""
echo "======================================================="
echo "[4/6] NixOS sistemi kuruluyor..."
echo "======================================================="
sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-install --flake ".#$HOSTNAME"

# ============================================================================
#  [5/6] Konfigürasyon dosyalarını kopyala
# ============================================================================

echo ""
echo "======================================================="
echo "[5/6] Konfigürasyon dosyaları ~/nixos-config'e kopyalanıyor..."
echo "======================================================="
sudo mkdir -p "/mnt/home/$KULLANICI/nixos-config"
sudo cp -r . "/mnt/home/$KULLANICI/nixos-config"

# ============================================================================
#  [6/6] Dosya sahipliğini ayarla
# ============================================================================

echo ""
echo "======================================================="
echo "[6/6] Dosya yetkileri ayarlanıyor..."
echo "======================================================="
# nixos-install kullanıcıyı oluşturduğunda UID otomatik atanır.
# /etc/passwd'den gerçek UID/GID'yi oku (1000 varsaymak yerine)
if [ -f /mnt/etc/passwd ]; then
    USER_UID=$(grep "^${KULLANICI}:" /mnt/etc/passwd | cut -d: -f3)
    USER_GID=$(grep "^${KULLANICI}:" /mnt/etc/passwd | cut -d: -f4)
fi

# Eğer passwd'den okunamadıysa varsayılan değerleri kullan
USER_UID="${USER_UID:-1000}"
USER_GID="${USER_GID:-100}"

sudo chown -R "$USER_UID:$USER_GID" "/mnt/home/$KULLANICI/nixos-config"
sudo chown -R "$USER_UID:$USER_GID" "/mnt/home/$KULLANICI/.ssh"
echo "  ✅ Yetkiler ayarlandı (UID:$USER_UID GID:$USER_GID)"

echo ""
echo "======================================================="
echo " KURULUM BAŞARIYLA TAMAMLANDI! 🎉"
echo "======================================================="
echo "  Kullanıcı:   $KULLANICI"
echo "  Hostname:    $HOSTNAME"
echo "  Disk:        $SECILEN_DISK ($DISK_TIPI)"
echo "  Şifreleme:   $LUKS_DURUM"
echo "  Swap:        $SWAP_BOYUT"
echo "-------------------------------------------------------"
echo "1. Sistemi yeniden başlat: reboot"
echo "2. Yeni sistemde ~/nixos-config klasörüne gir."
echo "3. Kurulum sonrası betiğini çalıştır: ./indirmesonrasi.sh"
echo "======================================================="
