{
  config,
  username,
  ...
}:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";

  targets.genericLinux.enable = true;

  xdg.configFile."home-manager/flake.nix".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/flake.nix";
}
