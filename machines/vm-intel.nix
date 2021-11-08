{ config, pkgs, ... }: {
  imports = [
    ./vm-shared.nix
  ];

  virtualisation.vmware.guest.enable = true;


  #hardware.opengl.extraPackages = with pkgs; [ vaapiIntel libvdpau-va-gl vaapiVdpau intel-ocl ];
 hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
    
    ];
  };
  hardware.opengl.driSupport= true;
  
  # Interface is this on Intel Fusion
  networking.interfaces.ens33.useDHCP = true;

  # Shared folder to host works on Intel
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };
}
