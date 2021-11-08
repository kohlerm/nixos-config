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
  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix)
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/1dd99a6c91b4a6909e66d0ee69b3f31995f38851.tar.gz;
      sha256 = "1z8gx1cqd18s8zgqksjbyinwgcbndg2r6wv59c4qs24rbgcsvny9";
    }))
  ];
}
