{
  dan = {
    roles = {
      ssh.enable = true;
      git = {
        enable = true;
        repos = [
          "nix-config"
          "nix-secrets"
        ];
      };
    };
    home.stateVersion = "24.11";
  };

}
