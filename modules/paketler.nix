{
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
 environment.systemPackages = with pkgs; [
vim
    git
    proton-pass
    chromium
    virt-manager
    proton-vpn
    fastfetch
    kdePackages.kcalc
    libreoffice
    nh
    nix-tree
    alejandra
    sops
    ssh-to-age
    antigravity
    distrobox
    (lib.hiPrio uutils-coreutils-noprefix)
    pkgs.tailscale
    pkgs.traceroute
    keepassxc
    pkgs.zapret2
    pkgs.celeste
    btop
    pkgs.code-cursor
    libva-utils # 'vainfo' komutunu sağlar
    vdpauinfo # VDPAU donanım hızlandırma durumu için
    pkgs.xinput
    # Ekran Kartı ve PCI Teşhis Araçları
    pciutils # 'lspci' komutunu sağlar
    mesa-demos # 'glxinfo' komutunu sağlar (DÜZELTİLEN KISIM)
    wayland-utils # 'wayland-info' komutu ile Wayland protokollerini listeler
    #######gnome için
    # adwaita-icon-theme
    # gnome-themes-extra
    # kdePackages.breeze-icons
    ###########
    brave
    rofi
    kitty
    hyprlauncher
    waybar
    nerd-fonts.jetbrains-mono
    grim # Wayland ekran görüntüsü aracı
    slurp # İnteraktif alan seçici (grim ile)
    wl-clipboard # Wayland clipboard (wl-copy komutu)
    blueman
    kdePackages.dolphin
unzip 
imv 
vscode 
jdk17
protonmail-desktop
    awww   # Wallpaper daemon (eski adı swww, animasyonlu geçiş)
anyrun 
    desktop-file-utils # Dolphin "Open With" menüsü için MIME cache oluşturur
vlc
mullvad-browser
aichat
nmap 
unixtools.ifconfig
#open-interpreter
opencode
];
}
