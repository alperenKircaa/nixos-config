{
  config,
  pkgs,
  username,
  ...
}: {
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = ["networkmanager" "wheel" "libvirtd"];
    hashedPasswordFile = config.sops.secrets.user_password.path;
    shell = pkgs.fish;
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  environment.shellAliases = {
    okul-gec = "sudo nixos-rebuild switch --flake . && sudo /run/current-system/specialisation/okul-agi/bin/switch-to-configuration switch";
    guncelle = "nh os switch /home/${username}/nixos-config";
    temizle = "nh clean";
  };
  environment.variables.NH_FLAKE = "/home/${username}/nixos-config";
  # shell is set in the users.users block above
  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
     set -g fish_greeting ""
    fastfetch --logo ${../bayrak.txt} --logo-color-1 red
  '';
}
