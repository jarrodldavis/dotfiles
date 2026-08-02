{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    git
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "26.05";
}
