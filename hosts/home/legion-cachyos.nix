{
  username,
  ...
}:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";

  targets.genericLinux.enable = true;
}
