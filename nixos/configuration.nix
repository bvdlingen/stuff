{config, pkgs, ... }:

{
    imports = [
        # Include the results of the hardware scan
        ./hardware-configuration.nix
    ];

    boot = {
        # Clean the /tmp dir at boot
        cleanTmpDir = true;
        # Latest kernel
        kernelPackages = pkgs.linuxPackages_latest;
        loader = {
            # I don't wanna see you
            timeout = 0;

            # BIOS = GRUB2
            grub = {
                # Enable it
                enable = true;
                # Use version 2
                version = 2;
                # Device where it installs
                device = "/dev/sda";
            };
        };

        # Pretty logo at boot
        plymouth.enable = true;
    };

    security = {
        sudo.wheelNeedsPassword = false;

        pam.services.sddm.allowNullPassword = true;
    };

    i18n = {
        # Set the default language, boludo
        defaultLocale = "es_AR.UTF-8";
        # Set the console keymap
        consoleKeyMap = "la-latin1";
    };

    fonts = {
        # Store all the fonts in one place
        enableFontDir = true;
        # Enable default fonts
        enableDefaultFonts = true;
        # Enable Microsoft Core Fonts
        enableCoreFonts = true;

        # Add more fonts
        fonts = with pkgs; [
            hack-font
            noto-fonts
            noto-fonts-emoji
            ubuntu_font_family
        ];
    };

    users = {
        # Set the default shell
        defaultUserShell = pkgs.zsh;

        # Extra users
        extraUsers.casa = {
            # Username
            name = "casa";
            # Realname
            description = "Casa";
             # We're not a system user (daemons and that stuff)
            isNormalUser = true;
            # Add to wheel group for sudo-ing
            extraGroups = [
                "wheel"
            ];
            # Create the home directory for the user (very important)
            createHome = true;
        };
    };

    # The hostname
    networking.hostName = "pandora";
    # The time zone
    time.timeZone = "America/Argentina/Buenos_Aires";
    # Enable the Z Shell
    programs.zsh.enable = true;
    # Enable NetworkManager
    networking.networkmanager.enable = true;
    # Enable PulseAudio
    hardware.pulseaudio.enable = true;

    services = {
        xserver = {
            # It's useful for using the desktop, I guess
            enable = true;
            # AMD drivers
            videoDrivers = ["ati"];
            # Forcibly kill X
            enableCtrlAltBackspace = true;
            # Keyboard layout
            layout = "latam";

            # Use SDDM as display manager
            displayManager.sddm = {
                enable = true;
                autoNumlock = true;

                # Autologin to my only one user
                autoLogin = {
                    enable = true;
                    user = "casa";
                };
            };

            # Use Plasma as desktop environment
            desktopManager.plasma5 = {
                enable = true;
            };

            # Default to libinput
            libinput.enable = true;
        };

        # Time force, time force!
        timesyncd.enable = true;
        # Rebuild the locate database daily
        locate.enable = true;
    };

    environment.systemPackages = with pkgs; [
        # Accesories
        ark
        kcalc
        spectacle

        # Development
        vscode
        go

        # Graphics
        gimp
        gwenview
        inkscape

        # Interwebz
        google-chrome
        kde-telepathy
        konversation
        qbittorrent

        # Multimedia
        smplayer

        # Office
        libreoffice-fresh

        # System
        dolphin
        kdeApplications.dolphin-plugins
        konsole
        gparted

        # Extra useful stuff
        breeze-gtk
        ffmpegthumbs
        kdeApplications.kio-extras

        # CLI stuff
        git
        man
        nano
        neofetch
        tree
        unrar
        unzip
        yadm

        # Libraries
        libdvdcss
    ];

    nix = {
        # Automatically optimize the Nix store
        autoOptimiseStore = true;
        # Cores used for building (0 means all available cores)
        buildCores = 0;
        # Number of jobs to use
        maxJobs = 5;
        # Use a sandbox for building packages
        useSandbox = true;

        # Automatically garbage collect unused stuff
        gc.automatic = true;
    };

    nixpkgs.config = {
        # Allow unfree packages (for Chrome)
        allowUnfree = true;

        # Override package settings
        packageOverrides = pkgs: {
            ark = pkgs.ark.override {
                # Enable unrar
                unfreeEnableUnrar = true;
            };

            qbittorrent = pkgs.qbittorrent.override {
                # I dont need this
                webuiSupport = false;
            };

            libreoffice-fresh = pkgs.libreoffice-fresh.override {
                # Use my language only :)
                langs = ["es"];
            };
        };
    };

    system = {
        # Live in the rollin'
        defaultChannel = "https://nixos.org/channels/nixos-unstable";

        # Unnattended upgrades
        autoUpgrade = {
            enable = true;
            channel = "https://nixos.org/channels/nixos-unstable";
        };
    };
}
