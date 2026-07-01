{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "alperenKircaa";
        email = "alpkirca@proton.me";
      };

      alias = {
        co = "checkout";
        ci = "commit";
        st = "status";
        br = "branch";
        hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
    };
  };
}
