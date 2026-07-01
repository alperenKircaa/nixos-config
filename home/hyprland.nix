{pkgs, ...}: {
  # Hyprland Lua konfigürasyonunu repo'dan ~/.config/hypr/hyprland.lua'ya symlink'le
  # Kaynak dosya: ~/nixos-config/hyprland/hyprland.lua
  # Değişiklik yapmak için repo'daki dosyayı düzenle, sonra `nixos-rebuild switch` çalıştır.
  xdg.configFile."hypr/hyprland.lua" = {
    source = ../hyprland/hyprland.lua;
    force = true;
  };

  xdg.configFile."hypr/waybar-autohide.sh" = {
    source = ../hyprland/waybar-autohide.sh;
    executable = true;
  };

  # Wallpaper scriptleri — ~/.local/bin/ altına koy (PATH'de olur)
  home.file.".local/bin/set-wallpaper.sh" = {
    source = ../hyprland/set-wallpaper.sh;
    executable = true;
  };

  home.file.".local/bin/restore-wallpaper.sh" = {
    source = ../hyprland/restore-wallpaper.sh;
    executable = true;
  };

  # Dolphin sağ-tık menüsü: "Wallpaper Olarak Ayarla"
  home.file.".local/share/kio/servicemenus/set-wallpaper.desktop" = {
    source = ../hyprland/set-wallpaper.desktop;
  };
}

