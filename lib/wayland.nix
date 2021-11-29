{
  # ...
  inputs = {
    # ...
    nixpkgs-wayland  = { url = "github:nix-community/nixpkgs-wayland"; };

    # only needed if you use as a package set:
    nixpkgs-wayland.inputs.nixpkgs.follows = "cmpkgs";
    nixpkgs-wayland.inputs.master.follows = "master";
  };

  outputs = inputs: {
    nixosConfigurations."my-laptop-hostname" =
    let system = "x86_64-linux";
    in nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [({pkgs, config, ... }: {
        config = {
          nix = {
            # add binary caches
            binaryCachePublicKeys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
              # ...
            ];
            binaryCaches = [
              "https://cache.nixos.org"
              "https://nixpkgs-wayland.cachix.org"
              # ...
            ];
          };

          # use it as an overlay
          nixpkgs.overlays = [ inputs.nixpkgs-wayland.overlay ];

          # pull specific packages (built against inputs.nixpkgs, usually `nixos-unstable`)
          environment.systemPackages = with pkgs; [
            inputs.nixpkgs-wayland.packages.${system}.waybar
          ];
        };
      })];
    };
  };
}
