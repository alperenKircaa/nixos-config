{
  config,
  pkgs,
  ...
}: {
  sops = {
    # Default secrets file
    defaultSopsFile = ../secrets.yaml;
    # Validate that secrets.yaml exists and is well-formed at eval time
    validateSopsFiles = true;

    # Automatically import the host SSH key into age format
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    # Define secrets
    secrets.school_wifi_password = {
      owner = "root";
    };
    secrets.home_wifi_password = {
      owner = "root";
    };
    secrets.user_password = {
      neededForUsers = true;
    };
  };
}
