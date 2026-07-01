{
  config,
  pkgs,
  ...
}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      max-jobs = "auto"; # use all available CPU cores for parallel builds
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true; # enforce that profiled processes are actually confined
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # bluetooth & fstrim are configured in driver.nix
  services.flatpak.enable = true;
  services.fprintd.enable = true;
  virtualisation.libvirtd.enable = true;

  # Podman — distrobox compatible (rootless Docker had /dev/ptmx issues on NixOS)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # provides a "docker" CLI alias pointing to podman
    defaultNetwork.settings.dns_enabled = true;
  };

  # Required for rootless Podman / distrobox user namespaces
  security.unprivilegedUsernsClone = true;
  programs.dconf.enable = true;
  # fish.enable lives in users.nix alongside the rest of the fish config
  programs.nix-ld.enable = true;
}
