# Web App kısayolları — Brave tarayıcıda --app modunda açılır
# Adres çubuğu olmadan, bağımsız pencere olarak çalışır (PWA benzeri)
{pkgs, ...}: let
  # Papirus ikon temasından WhatsApp ve YouTube ikonlarını al
  papirus = pkgs.papirus-icon-theme;
  whatsappIcon = "${papirus}/share/icons/Papirus/64x64/apps/whatsapp.svg";
  youtubeIcon = "${papirus}/share/icons/Papirus/64x64/apps/youtube.svg";
  # LinkedIn ikonu Papirus'ta yok — assets klasöründen alıyoruz
  linkedinIcon = ../assets/icons/linkedin.svg;
in {
  # ====================================================================
  # İKON TEMASI — Papirus-Dark
  # ====================================================================
  gtk.iconTheme = {
    name = "Papirus-Dark";
    package = papirus;
  };

  # ====================================================================
  # WEB APP DESKTOP ENTRY'LERİ
  # ====================================================================
  xdg.desktopEntries = {
    whatsapp = {
      name = "WhatsApp";
      comment = "WhatsApp Web — Brave ile açılır";
      exec = "brave --app=https://web.whatsapp.com";
      icon = "${whatsappIcon}";
      terminal = false;
      type = "Application";
      categories = ["Network" "InstantMessaging"];
    };

    linkedin = {
      name = "LinkedIn";
      comment = "LinkedIn — Brave ile açılır";
      exec = "brave --app=https://www.linkedin.com";
      icon = "${linkedinIcon}";
      terminal = false;
      type = "Application";
      categories = ["Network" "Office"];
    };

    youtube = {
      name = "YouTube";
      comment = "YouTube — Brave ile açılır";
      exec = "brave --app=https://www.youtube.com";
      icon = "${youtubeIcon}";
      terminal = false;
      type = "Application";
      categories = ["Network" "AudioVideo"];
    };
  };
}
