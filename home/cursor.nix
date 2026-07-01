{
  config,
  pkgs,
  ...
}: {
  # ====================================================================
  # CURSOR THEME (Fare İmleci Teması)
  # ====================================================================
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
