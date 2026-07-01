{
  config,
  pkgs,
  inputs,
  ...
}: {
  # ====================================================================
  # DISPLAY MANAGERS (Giriş Ekranı Yöneticileri)
  # Uyarı: Aynı anda sadece BİR tanesini aktif (.enable = true) yapın!
  # ====================================================================

  services.displayManager.sddm.enable = true; # KDE/Plasma ve genel kullanım için önerilir
  services.displayManager.sddm.wayland.enable = true; # Wayland (Hyprland) için gerekli
  # services.xserver.displayManager.gdm.enable = true;    # GNOME ile standart gelir
  # services.xserver.displayManager.lightdm.enable = true; # XFCE/Mate/WM'ler için hafif bir alternatif
  # services.greetd.enable = true;                  # Wayland (Hyprland/Sway) için minimal alternatif
  # services.displayManager.cosmic-greeter.enable = true;  ####### COSMİC
  # ====================================================================
  # DESKTOP ENVIRONMENTS (Masaüstü Ortamları)
  # ====================================================================

  #COSMİC
  #  services.desktopManager.cosmic.enable = true;
  # KDE Plasma 6 (Wayland destekli)
  #  services.desktopManager.plasma6.enable = true;

  # GNOME
  #  services.xserver.desktopManager.gnome.enable = true;

  # XFCE
  # services.xserver.desktopManager.xfce.enable = true;

  # Cinnamon
  # services.xserver.desktopManager.cinnamon.enable = true;

  # MATE
  # services.xserver.desktopManager.mate.enable = true;

  # Pantheon (Elementary OS Masaüstü)
  # services.xserver.desktopManager.pantheon.enable = true;

  # LXQt
  # services.xserver.desktopManager.lxqt.enable = true;

  # ====================================================================
  # TILING WINDOW MANAGERS - WAYLAND (Döşemeli Pencere Yöneticileri)
  # ====================================================================

  # Hyprland (Modern, animasyonlu Wayland TWM) — Flake'den sabitlenmiş sürüm
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.x86_64-linux.hyprland;
    portalPackage = inputs.hyprland.packages.x86_64-linux.xdg-desktop-portal-hyprland;
  };

  # Sway (i3'ün Wayland alternatifi)
  # programs.sway = {
  #   enable = true;
  #   wrapperFeatures.gtk = true;
  # };

  # ====================================================================
  # TILING WINDOW MANAGERS - X11 (Döşemeli Pencere Yöneticileri)
  # ====================================================================

  # i3wm
  # services.xserver.windowManager.i3.enable = true;

  # bspwm
  # services.xserver.windowManager.bspwm.enable = true;

  # AwesomeWM
  # services.xserver.windowManager.awesome.enable = true;

  # XMonad
  # services.xserver.windowManager.xmonad = {
  #   enable = true;
  #   enableContribAndExtras = true;
  # };

  # Qtile
  # services.xserver.windowManager.qtile.enable = true;
}
