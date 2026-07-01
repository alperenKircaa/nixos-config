{...}: {
  # Waybar konfigürasyonunu repo'dan ~/.config/waybar/ altına symlink'le
  # Config dosyaları: ~/nixos-config/hyprland/waybar/
  # Değişiklik yapmak için repo'daki dosyaları düzenle, sonra `nixos-rebuild switch` çalıştır.

  xdg.configFile."waybar/config.jsonc" = {
    source = ../hyprland/waybar/config.jsonc;
  };

  xdg.configFile."waybar/style.css" = {
    source = ../hyprland/waybar/style.css;
  };
}
