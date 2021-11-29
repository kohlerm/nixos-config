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
     #enable = true;
     autorun = true;
    layout = "us";
    dpi = 220;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "scale";
    };
    videoDrivers = [ "vmware" ];
    displayManager = {
     #defaultSession = "sway";
     lightdm.enable = false;
     #gdm.enable = true;
     #gdm.wayland = true;

      # AARCH64: For now, on Apple Silicon, we must manually set the
      # display resolution. This is a known issue with VMware Fusion.
      sessionCommands = ''
        ${pkgs.xlibs.xset}/bin/xset r rate 200 60
      '' + (if currentSystem == "aarch64-linux" then ''
        ${pkgs.xorg.xrandr}/bin/xrandr -s '2880x1800'
      '' else "");
    };

    windowManager = {
   #   i3.enable = true;
    };
  };


#services.xserver.windowManager.i3.package = pkgs.i3-gaps;

 systemd.user.targets.sway-session = {
    description = "Sway compositor session";
    documentation = [ "man:systemd.special(7)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  systemd.user.services.sway = {
    description = "Sway - Wayland window manager";
    documentation = [ "man:sway(5)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    # We explicitly unset PATH here, as we want it to be set by
    # systemctl --user import-environment in startsway
    environment.PATH = lib.mkForce null;
    environment.WLR_NO_HARDWARE_CURSORS = "1";
    environment.MOZ_ENABLE_WAYLAND="1";
    environment.SDL_VIDEODRIVER="wayland";
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --debug
      '';
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  /* services.redshift = {
    enable = true;
    # Redshift with wayland support isn't present in nixos-19.09 atm. You have to cherry-pick the commit from https://github.com/NixOS/nixpkgs/pull/68285 to do that.
    package = pkgs.redshift-wlr;
  }; */

          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
             "vscode"
             "google-chrome"
           ];

           programs = {
             sway = {
               enable = true;
               extraPackages = with pkgs;
               [
                 wofi
                 swayidle
                 swaylock
                 weston
                 wl-clipboard
                 xwayland
                 waybar
               ];
               extraSessionCommands = "
            export XKB_DEFAULT_LAYOUT=us
            export XKB_DEFAULT_VARIANT=nodeadkeys
            export WLR_NO_HARDWARE_CURSORS=1
            export MOZ_ENABLE_WAYLAND=1
              export SDL_VIDEODRIVER=wayland
        # needs qt5.qtwayland in systemPackages
        # for older version of Qt
        export QT_WAYLAND_DISABLE_WINDOWDECORATION='1'
        # Fix for some Java AWT applications (e.g. Android Studio),
        # use this if they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
               ";
             };
           };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = true;

programs.waybar.enable = true;
environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && startsway
  '';



 systemd.user.services.waybar.unitConfig.wants = [ "sway.service" ];

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
    imv
    # This is needed for the vmware user tools clipboard to work.
    # You can test if you don't need this by deleting this and seeing
    # if the clipboard sill works.
    gtkmm3
    foot
    flashfocus

    # VMware on M1 doesn't support automatic resizing yet and on
    # my big monitor it doesn't detect the resolution either so we just
    # manualy create the resolution and switch to it with this script.
    # This script could be better but its hopefully temporary so just force it.
    (writeShellScriptBin "xrandr-4k" ''
      xrandr -s 3840x2160
    '')
    (
      pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = ''
          #! ${pkgs.bash}/bin/bash
          # first import environment variables from the login manager
          systemctl --user import-environment
          # then start the service
          exec systemctl --user start sway.service
        '';
      }
    )


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
