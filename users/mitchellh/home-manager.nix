{ config, lib, pkgs, ... }:

let sources = import ../../nix/sources.nix; in {
  xdg.enable = true;
   # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs.fzf
    pkgs.git-crypt
    pkgs.htop
    pkgs.jq
    #pkgs.rofi
    pkgs.go
    pkgs.gopls
    pkgs.tree
    pkgs.watch
    pkgs.zathura
    pkgs.bat
    pkgs.tlaplusToolbox
    pkgs.tetex
    pkgs.glxinfo
    pkgs.sqlite
    pkgs.firefox
    pkgs.hwinfo
    pkgs.ripgrep
    pkgs.ffmpeg
    pkgs.nix-prefetch-github
    pkgs.cloudfoundry-cli
    pkgs.nixpkgs-fmt
    pkgs.dbeaver
    pkgs.google-chrome
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "less -FirSwX";
    #tmpfs is pretty small avoids problems with GO builds
    GOTMPDIR="/dev/shm";
  };

  home.file.".inputrc".source = ./inputrc;
  home.file.".wall.jpg".source = ./wallpaper.jpg;
  #xdg.configFile."i3/config".text = builtins.readFile ./i3;
  xdg.configFile."sway/config".text = builtins.readFile ./sway;
  #xdg.configFile."rofi/config.rasi".text = builtins.readFile ./rofi;
  xdg.configFile."wofi/config.rasi".text = builtins.readFile ./wofi;

  # tree-sitter parsers
  xdg.configFile."nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
  xdg.configFile."nvim/queries/proto/folds.scm".source =
    "${sources.tree-sitter-proto}/queries/folds.scm";
  xdg.configFile."nvim/queries/proto/highlights.scm".source =
    "${sources.tree-sitter-proto}/queries/highlights.scm";
  xdg.configFile."nvim/queries/proto/textobjects.scm".source =
    ./textobjects.scm;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = true;

services = {
   picom = {
      enable = true;
      package = pkgs.picom.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "ibhagwan";
          repo = "picom";
          rev = "c4107bb6cc17773fdc6c48bb2e475ef957513c7a";
          sha256 = "1hVFBGo4Ieke2T9PqMur1w4D0bz/L3FAvfujY9Zergw=";

        };
      });
      shadow = true;
      blur = true;
      fade = true;
      fadeDelta = 10;
      experimentalBackends = false;
      extraOptions = ''
        blur-method = "dual_kawase";
        blur-strength = 10;
        corner-radius = 15;
        detect-client-opacity = true;
        rounded-corners-exclude = [
      "class_g = 'i3bar'"
      ];
      inactiveOpacity = 0.9;  
      '';
      
      blurExclude = [
        "window_type *= 'menu'"
        "window_type *= 'dropdown_menu'"
        "window_type *= 'popup_menu'"
        "window_type *= 'utility'"
        "class_g = 'i3-frame'"
        "class_g = 'kitty' && !focused"
      ];

      opacityRule = [
        "90:class_g != 'kitty' && !focused"
      ];
      shadowExclude = [
        "window_type *= 'menu'"
        "window_type *= 'dropdown_menu'"
        "window_type *= 'popup_menu'"
        "window_type *= 'utility'"
        "class_g = 'i3-frame'"
        "class_g = 'Rofi'"
        "class_g = 'kitty'"
      ];
    }; 
  };


  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    initExtra = builtins.readFile ./bashrc;

    shellAliases = {
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
       gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gs = "git status";
      gt = "git tag";
    };
  };
  
  programs.vscode = {
      enable = true;
      #package = pkgs.vscodium;  
   extensions = with pkgs.vscode-extensions; [
    # not really needed only use file generated with ../scripts/update_vscode_exts.sh
  ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace (import ./vscode-exts.nix).extensions; 
  
  
       
    };
  
  programs.direnv= {
    enable = true;
    config = {
      whitelist = {
        prefix= [
          "$HOME/code/go/src/github.com/hashicorp"
          "$HOME/code/go/src/github.com/mitchellh"
        ];

        exact = ["$HOME/.envrc"];
      };
    };
  };
   programs.direnv.nix-direnv.enable = true;
  # optional for nix flakes support
  programs.direnv.nix-direnv.enableFlakes = true;
  
  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" [
      "source ${sources.theme-bobthefish}/fish_prompt.fish"
      "source ${sources.theme-bobthefish}/fish_right_prompt.fish"
      "source ${sources.theme-bobthefish}/fish_title.fish"
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
    ]);

    shellAliases = {
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gs = "git status";
      gt = "git tag";

      # Two decades of using a Mac has made this such a strong memory
      # that I'm just going to keep it consistent.
      pbcopy = "xclip";
      pbpaste = "xclip -o";
    };

    plugins = map (n: {
      name = n;
      src  = sources.${n};
    }) [
      "fish-fzf"
      "fish-foreign-env"
      "theme-bobthefish"
    ];
  };

  programs.git = {
    enable = true;
    delta.enable = true;
    userName = "Markus Kohler";
    userEmail = "markus.kohler@gmail.com";
    
    aliases = {
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "kohlerm";
      push.default = "tracking";
      init.defaultBranch = "main";
      
    };
  };

  programs.go = {
    enable = true;
    goPath = "code/go";
    #goPrivate = [ "github.com/mitchellh" "github.com/hashicorp" "rfc822.mx" ];
  };

  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    shortcut = "l";
    secureSocket = false;

    extraConfig = ''
      set -ga terminal-overrides ",*256col*:Tc"

      set -g @dracula-show-battery false
      set -g @dracula-show-network false
      set -g @dracula-show-weather false

      bind -n C-k send-keys "clear"\; send-keys "Enter"

      run-shell ${sources.tmux-pain-control}/pain_control.tmux
      run-shell ${sources.tmux-dracula}/dracula.tmux
    '';
  };

  

  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";
       font = {
        normal = {
          family = "Iosevka Nerd Font";
          
        };
        size = 11;

      };
      colors = {
        primary = {
          foreground = "#dcdfe4";
          background  = "#282c34";
        };
        selection = {
          text = "#000000";
          background  ="#FFFACD";
        };
      };

      key_bindings = [
     
      ];
    };
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  programs.i3status = {
    enable = true;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;

    plugins = with pkgs; [
      customVim.vim-fish
      customVim.vim-fugitive
      customVim.vim-misc
      customVim.vim-tla
      customVim.pigeon
      customVim.AfterColors

      customVim.vim-nord
      customVim.nvim-lspconfig
      customVim.nvim-treesitter
      customVim.nvim-treesitter-playground
      customVim.nvim-treesitter-textobjects

      vimPlugins.ctrlp
      vimPlugins.vim-airline
      vimPlugins.vim-airline-themes
      vimPlugins.vim-eunuch
      vimPlugins.vim-gitgutter

      vimPlugins.vim-markdown
      vimPlugins.vim-nix
      vimPlugins.typescript-vim
    ];

    extraConfig = (import ./vim-config.nix) { inherit sources; };
  };

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "tty";

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  xresources.extraConfig = builtins.readFile ./Xresources;
  
  # Make cursor not tiny on HiDPI screens
  xsession.pointerCursor = {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
  };
}
