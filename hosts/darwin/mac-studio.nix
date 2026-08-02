{
  username,
  ...
}:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking = {
    hostName = "Rods-Mac-Studio";
    computerName = "Rod’s Mac Studio";
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system.primaryUser = username;

  programs.zsh = {
    enable = true;
    promptInit = "";
    interactiveShellInit = ''
      bindkey -v
    '';
  };

  system.stateVersion = 7;
}
