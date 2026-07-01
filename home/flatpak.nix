# ~/nixos-config/home/flatpak.nix
{
  config,
  pkgs,
  ...
}: {
  services.flatpak = {
    enable = true;

    # Flathub reposunu otomatik olarak ekler
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    # İndirmek istediğin Flatpak uygulamalarının listesi
    packages = [
      "app.zen_browser.zen"
      "com.discordapp.Discord"
      "org.fedoraproject.MediaWriter"
      "io.github.mezoahmedii.Picker"
      "it.mijorus.smile"
      "com.github.zadam.trilium"
      "com.valvesoftware.Steam"
      "com.transmissionbt.Transmission"
       "org.localsend.localsend_app" 
      # Buraya istediğin kadar ekleyebilirsin
    ];

    # Uygulamaların arkaplanda otomatik güncellenmesini istersen:
    update.auto = {
      enable = true;
      onCalendar = "daily"; # Her gün günceller
    };
  };
}
