{
  description = "Alperen'in NixOS Flake Yapılandırması (Disko + Özel ISO + Home Manager + Flatpak)";

  inputs = {
    # NixOS paket kaynağı
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Disko aracı
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Deklaratif Flatpak Yönetimi
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Sops-nix (Secret Management)
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland — v0.55.3'e sabitlenmiş
    hyprland.url = "github:hyprwm/Hyprland/v0.55.3";
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    home-manager,
    nix-flatpak,
    sops-nix,
    hyprland,
    ...
  } @ inputs: let
    username = "alperenkirca";
  in {
    nixosConfigurations = {
      # ===================================================================
      # 1. ANA BİLGİSAYARIN YAPIlandırması (Kurulu/Kurulacak Sistem)
      # ===================================================================
      thinkpad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs username;};
        modules = [
          # Ana ayar dosyanı çağırıyoruz
          ./configuration.nix

          # Sops-nix modülü
          sops-nix.nixosModules.sops

          # Disko modülünü sisteme dahil ediyoruz
          disko.nixosModules.disko

          # Home Manager modülünü sisteme dahil ediyoruz
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit username;};

            home-manager.users.${username} = {
              imports = [
                ./home.nix
                nix-flatpak.homeManagerModules.nix-flatpak
              ];
            };
          }
        ];
      };

      # ===================================================================
      # 2. ÖZEL KURULUM USB'Sİ (ISO) YAPIlandırması
      # ===================================================================
      custom-iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # NixOS Minimal Kurulum ISO'su altyapısı
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

          ({pkgs, ...}: {
            # Kurulum yaparken canlı sistemde (Live CD) lazım olacak araçlar
            environment.systemPackages = with pkgs; [
              git
              neovim
              curl
              wget
              dialog # Kurulum sihirbazı TUI arayüzü için
            ];

            # Canlı sistemde Flake komutlarının çalışması için baştan yetki veriyoruz
            nix.settings.experimental-features = ["nix-command" "flakes"];

            # ===================================================================
            # SSH YETKİLENDİRME (ISO'ya Güvenli Giriş)
            # ===================================================================
            # Bu key sadece ISO'dan (Live USB) SSH ile bağlanmak içindir.
            # Başka biri bu config'i kullanacaksa KENDİ public key'ini buraya
            # koymalı, veya aşağıdaki parola ile giriş seçeneğini kullanabilir.
            # ===================================================================
            users.users.nixos.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDjw9rWE+EPml0yKV13+8jL7GPpb7ZP0dtsaaQR84wH4 alpkirca@proton.me"
            ];
            services.openssh = {
              enable = true;
              settings.PasswordAuthentication = true; # ISO'da parola ile de girilebilsin
            };
          })
        ];
      };
    };
  };
}
