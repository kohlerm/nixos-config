{ pkgs, ... }:

{
  users.users.mitchellh = {
    isNormalUser = true;
    home = "/home/mitchellh";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$r5lqrw5ZhSSapNmt$hOORz3HkwCY7mKOl6aY9o5q8/w9VfHFP96rTzhYmzx7.OqnVQwlmSSIJgz0aBC0IGhRKPVYe1IM..0f26vrBX.";

  };
  users.users.kohlerm = {
    isNormalUser = true;
    home = "/home/kohlerm";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$r5lqrw5ZhSSapNmt$hOORz3HkwCY7mKOl6aY9o5q8/w9VfHFP96rTzhYmzx7.OqnVQwlmSSIJgz0aBC0IGhRKPVYe1IM..0f26vrBX.";

  };
  
}
