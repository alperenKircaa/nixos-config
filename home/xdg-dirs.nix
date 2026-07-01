{config, ...}: {
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    # Senkronize EDİLMEYECEK ve ana dizinde kalacak standart klasörler
    desktop = "${config.home.homeDirectory}/Desktop";
    download = "${config.home.homeDirectory}/Downloads";

    # Proton Drive'a gidecek (drivehome içine taşınan) standart XDG klasörleri
    documents = "${config.home.homeDirectory}/drivehome/Documents";
    music = "${config.home.homeDirectory}/drivehome/Music";
    pictures = "${config.home.homeDirectory}/drivehome/Pictures";
    videos = "${config.home.homeDirectory}/drivehome/Videos";
    templates = "${config.home.homeDirectory}/drivehome/Templates";
    publicShare = "${config.home.homeDirectory}/drivehome/Public";

    # XDG_PROJECTS_DIR resmi XDG standardında yer almaz, bu yüzden onu extraConfig ile tanımlıyoruz
    extraConfig = {
      XDG_PROJECTS_DIR = "${config.home.homeDirectory}/drivehome/Projects";
    };
  };
}
