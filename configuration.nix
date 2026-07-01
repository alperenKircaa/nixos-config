{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./modules/paketler.nix
    ./modules/services.nix
    ./modules/DesktopEnvironments.nix
    ./modules/locals.nix
    ./modules/users.nix
    ./modules/karnel.nix
    ./modules/network-okul.nix
    ./modules/network-home.nix
    ./modules/network.nix
    ./modules/disk.nix
    ./modules/driver.nix
    ./modules/secrets-config.nix
    ./modules/snapshots.nix
  ];

  # Hyprland flake'inin binary cache'i — derlemeden hazır indirir
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  system.stateVersion = "26.05";
}
