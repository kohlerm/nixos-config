{ config, pkgs, currentSystem, lib, ... }:

{
  # We require 5.14 for VMware Fusion on M1.
  boot.kernelPackages = pkgs.linuxPackages_5_14;

  # use unstable nix so we can access flakes
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # We expect to run the VM on hidpi machines.
  hardware.video.hidpi.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define your hostname.
  networking.hostName = "dev";

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  #approved certifcates bundle file itself not checked in; comment it out if not needed
  security.pki.certificateFiles = [ ./approved.pem ];
  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # setup windowing environment
  services.xserver = {
    enable = true;
    layout = "us";
    dpi = 220;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "scale";
    };
    videoDrivers = [ "vmware" ];
    displayManager = {
      defaultSession = "none+i3";
      lightdm.enable = true;

      # AARCH64: For now, on Apple Silicon, we must manually set the
      # display resolution. This is a known issue with VMware Fusion.
      sessionCommands = ''
        ${pkgs.xlibs.xset}/bin/xset r rate 200 60
      '' + (if currentSystem == "aarch64-linux" then ''
        ${pkgs.xorg.xrandr}/bin/xrandr -s '2880x1800'
      '' else "");
    };

    windowManager = {
      i3.enable = true;
    };
  };


  services.xserver.windowManager.i3.package = pkgs.i3-gaps;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode"
  ];



  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = true;

  # Manage fonts. We pull these from a secret directory since most of these
  # fonts require a purchase.
  /*   fonts = {
    fontDir.enable = true;

    fonts = [
    (builtins.path {
    name = "custom-fonts";
    path = ../secret/fonts;
    recursive = true;
    })
    ];
    };
  */
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "Iosevka" ]; })
  ];




  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gnumake
    killall
    niv
    rxvt_unicode
    xclip
    feh
    # This is needed for the vmware user tools clipboard to work.
    # You can test if you don't need this by deleting this and seeing
    # if the clipboard sill works.
    gtkmm3
    atuin

    # VMware on M1 doesn't support automatic resizing yet and on
    # my big monitor it doesn't detect the resolution either so we just
    # manualy create the resolution and switch to it with this script.
    # This script could be better but its hopefully temporary so just force it.
    (writeShellScriptBin "xrandr-4k" ''
      xrandr -s 3840x2160
    '')
  ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = true;
  services.openssh.permitRootLogin = "yes";

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
