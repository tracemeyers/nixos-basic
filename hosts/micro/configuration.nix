# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cat = {
    isNormalUser = true;
    description = "cat";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  home-manager.users.cat = { pkgs, ... }: 
  let
    unstable = import <unstable> { config = { allowUnfree = true; }; };
  in 
  {
    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.11";
  
    # hint Electron apps to use Wayland:
    home.sessionVariables.NIXOS_OZONE_WL = "1";

    # https://fnordig.de/til/nix/home-manager-allow-unfree.html
    nixpkgs = {
      config = {
        allowUnfree = true;
        allowUnfreePredicate = (_: true);
      };
    };

    home.packages = with pkgs; [
      curl
      hyprlauncher
      rustdesk
      unstable.chromium
    ];

    programs.bash.enable = true;

    programs.kitty.enable = true; # required for the default Hyprland config

    wayland.windowManager.hyprland.enable = true; # enable Hyprland
    wayland.windowManager.hyprland.settings = {
      "$mod" = "ALT";
      bind =
        [
          "$mod, h, movefocus, l"
          "$mod, l, movefocus, r"
          "$mod, k, movefocus, u"
          "$mod, j, movefocus, d"
          "$mod, F, exec, firefox"
          "$mod, D, exec, hyprlauncher"
          "$mod, RETURN, exec, konsole"
          ", Print, exec, grimblast copy area"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (i:
              let ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );
      general = {
        gaps_in = 2;
        gaps_out = 2;
      };
    };
    wayland.windowManager.hyprland.extraConfig = ''
      exec-once = hyprpanel
    '';

    programs.hyprpanel = {
      enable = true;
      # Configure and theme almost all options from the GUI.
      # See 'https://hyprpanel.com/configuration/settings.html'.
      # Default: <same as gui>
      settings = {

        # Configure bar layouts for monitors.
        # See 'https://hyprpanel.com/configuration/panel.html'.
        # Default: null
        layout = {
          bar.layouts = {
            "0" = {
              left = [ "dashboard" "workspaces" ];
              middle = [ "media" ];
              right = [ "volume" "systray" "notifications" ];
            };
          };
        };

        bar.launcher.autoDetectIcon = true;
        bar.workspaces.show_icons = true;

        menus.clock = {
          time = {
            military = true;
            hideSeconds = true;
          };
	  weather.location = "2656543";
          weather.unit = "metric";
	  weather.weather_api_key = "13252f2ea9f4450cb55140545252711";
        };

        menus.dashboard.directories.enabled = false;
        menus.dashboard.stats.enable_gpu = true;

        theme.bar.transparent = true;

        theme.font = {
          name = "CaskaydiaCove";
          size = "10px";
        };
      };
    };
  };

  # Install firefox.
  programs.firefox = {
    enable = true;

    policies = {
      /* ---- EXTENSIONS ---- */
      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      ExtensionSettings = {
        "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
          /* 
          FINDING EXTENSION IDs
          If you’re having trouble finding a specific extension’s ID, you can
          always temporarily install it imperatively (the normal non-Nix way
          via the Firefox menu) and check the entries in the Add-ons section of
          about:support.
          */
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "http://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
      };
    };
  };


  programs.hyprland.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.git.enable = true;

  # hyprland???
  programs.hyprlock.enable = true;
  programs.dconf.enable = true;
  programs.tmux.enable = true;
  programs.nm-applet.indicator = true;

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.sauce-code-pro
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    kitty
    neovim

    # hyprland stuff
    # https://github.com/JaKooLit/NixOS-Hyprland/blob/main/modules/packages.nix
    hypridle
    hyprpolkitagent
    pyprland
    #uwsm
    hyprlang
    hyprshot
    hyprcursor
    mesa
    nwg-displays
    nwg-look
    wl-clipboard
    hyprland-qt-support # for hyprland-qt-support
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.rustdesk-server = {
    package = true;
    signal.enable = true;
    relay.enable = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
