#!/usr/bin/env bash

# Herhangi bir komut hata verirse betiği anında durdur
set -e

echo "======================================================="
echo "      NixOS Kurulum Sonrası Yapılandırma              "
echo "======================================================="

# 1. SOPS/Age Key Klasörünü Oluştur
mkdir -p ~/.config/sops/age

# 2. SSH Key'i Age Key'e Dönüştür
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "🔑 SSH anahtarı sops (age) formatına dönüştürülüyor..."
    ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
    chmod 600 ~/.config/sops/age/keys.txt
    echo "✅ Age key oluşturuldu: ~/.config/sops/age/keys.txt"
else
    echo "⚠️  HATA: ~/.ssh/id_ed25519 bulunamadı! Age key oluşturulamadı."
    exit 1
fi

# 3. SOPS Yapılandırmasını Güncelle (.sops.yaml)
echo ""
echo "🔑 .sops.yaml güncelleniyor..."
AGE_PUB_KEY=$(ssh-to-age -i ~/.ssh/id_ed25519.pub 2>/dev/null)

if [ -n "$AGE_PUB_KEY" ]; then
    KULLANICI=$(whoami)
    cat > ~/nixos-config/.sops.yaml << EOF
keys:
  - &user_${KULLANICI} ${AGE_PUB_KEY}
creation_rules:
  - path_regex: secrets\\.yaml\$
    key_groups:
      - age:
          - *user_${KULLANICI}
EOF
    echo "✅ .sops.yaml güncellendi (key: ${AGE_PUB_KEY:0:20}...)"

    # secrets.yaml yeniden şifrelemesi gerekiyorsa bilgilendir
    echo ""
    echo "⚠️  ÖNEMLİ: Eğer secrets.yaml'daki şifreleri kullanacaksan,"
    echo "   bu dosyayı kendi key'inle yeniden şifrelemelisin:"
    echo ""
    echo "   cd ~/nixos-config"
    echo "   sops updatekeys secrets.yaml"
    echo ""
else
    echo "⚠️  Age public key oluşturulamadı. .sops.yaml manuel güncellenmeli."
fi

# 4. NH Switch (Opsiyonel - Eğer her şey hazırsa)
echo ""
echo "Sistemi son haline getirmek için 'nh os switch' çalıştırmak ister misin?"
read -p "(e/H): " switch_onay

if [[ "$switch_onay" == "e" || "$switch_onay" == "E" ]]; then
    cd ~/nixos-config
    nh os switch .
else
    echo "Sistem switch işlemi atlandı. Manuel olarak 'nh os switch ~/nixos-config' çalıştırabilirsin."
fi

echo "======================================================="
echo " 🎉 Yapılandırma tamamlandı! "
echo "======================================================="
