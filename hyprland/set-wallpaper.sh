#!/usr/bin/env bash
# set-wallpaper.sh — awww ile wallpaper ayarlar ve son seçimi kaydeder
# Kullanım: set-wallpaper.sh <resim-yolu>

set -euo pipefail

IMAGE="${1:-}"

if [[ -z "$IMAGE" ]]; then
  echo "Kullanım: set-wallpaper.sh <resim-yolu>"
  exit 1
fi

if [[ ! -f "$IMAGE" ]]; then
  echo "Hata: '$IMAGE' bulunamadı."
  exit 1
fi

# awww-daemon çalışmıyorsa başlat
if ! pgrep -x awww-daemon > /dev/null; then
  awww-daemon &
  sleep 0.5
fi

# Wallpaper'ı animasyonlu olarak ayarla
awww img "$IMAGE" \
  --transition-type grow \
  --transition-duration 0.8 \
  --transition-fps 60

# Son seçilen wallpaper'ı kaydet (sonraki oturumda restore için)
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
mkdir -p "$(dirname "$STATE_FILE")"
echo "$IMAGE" > "$STATE_FILE"

echo "Wallpaper ayarlandı: $IMAGE"
