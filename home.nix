{
  config,
  pkgs,
  username,
  ...
}: {
  # Kullanıcı ve Dizin Bilgileri
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # home klasörü altındaki diğer konfigürasyonları buraya dahil ediyoruz.
  # Yeni bir dosya oluşturdukça buradaki yorum satırlarını kaldırabilir veya ekleyebilirsin.
  imports = [
    ./home/git.nix
    ./home/flatpak.nix
    ./home/xdg-dirs.nix
    ./home/cursor.nix
    ./home/hyprland.nix
    ./home/waybar.nix
    ./home/web-apps.nix
    # ./home/packages.nix
    ##  ./home/dotfiles.nix
  ];

  # Sadece Home Manager'ın çalışması için gereken temel paketler
  home.packages = with pkgs; [
    # Örnek: htop, neofetch vs.
  ];

  # SOPS age key — user-scoped, not system-wide
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "/home/${username}/.config/sops/age/keys.txt";
  };

  # ~/.local/bin'i PATH'e ekle (wallpaper scripti ve diğer özel scriptler için)
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Home Manager'ın kendi kendini yönetmesine izin ver
  programs.home-manager.enable = true;

  # Bu sürüm genelde sistemin kurulduğu NixOS sürümü ile aynı bırakılır.
  # Sık sık değiştirmene gerek yoktur.
  home.stateVersion = "26.05";
}
