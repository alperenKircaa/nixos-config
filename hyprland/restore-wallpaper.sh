#!/usr/bin/env bash
# restore-wallpaper.sh — Kayıtlı son wallpaper'ı yükler (Hyprland başlangıcında çalıştırılır)

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"

# awww-daemon başlat
awww-daemon &
sleep 0.5

# Kayıtlı wallpaper varsa yükle
if [[ -f "$STATE_FILE" ]]; then
  IMAGE="$(cat "$STATE_FILE")"
  if [[ -f "$IMAGE" ]]; then
    awww img "$IMAGE" --transition-type none
    exit 0
  fi
fi

# Kayıtlı yoksa Pictures klasöründeki ilk resmi dene
FIRST_IMAGE=$(find ~/Pictures -maxdepth 2 \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
  -type f | head -1)

if [[ -n "$FIRST_IMAGE" ]]; then
  awww img "$FIRST_IMAGE" --transition-type none
fi
