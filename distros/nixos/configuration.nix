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

        # Set up GRUB
        loader.grub.device = "/dev/sda";
    };

    security = {
        # Disable password for wheel users using sudo
        sudo.wheelNeedsPassword = false;

        # Disable password for SDDM
        pam.services.sddm.allowNullPassword = true;
    };

    # The hostname
    networking.hostName = "pandora";
    # The timezone
    time.timeZone = "America/Argentina/Buenos_Aires";

    i18n = {
        # Set the default language, boludo
        defaultLocale = "es_AR.UTF-8";
        # Set the console keymap
        consoleKeyMap = "la-latin1";
    };

    fonts = {
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
        defaultUserShell = pkgs.fish;

        # Extra users
        extraUsers.casa = {
                # Realname
                description = "Casa";
                # We're not a system user (daemons and that stuff)
                isNormalUser = true;
                # Add to wheel group for sudo-ing
                extraGroups = ["wheel"];
                # Create the home directory for the user (very important)
                createHome = true;
        };
    };

    # Enable the Fish
    programs.fish.enable = true;
    # Enable NetworkManager
    networking.networkmanager.enable = true;
    # Enable PulseAudio
    hardware.pulseaudio.enable = true;

    services = {
        xserver = {
            # It's useful for using the desktop, I guess
            enable = true;
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
        # Number of jobs to use
        maxJobs = 3;
        # Cores used for building
        buildCores = 3;

        # Automatically garbage collect unused stuff
        gc.automatic = true;
    };

    nixpkgs.config = {
        # Allow unfree packages (for Chrome and VSCode)
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
        };
    };

    system = {
        # Live in the rollin'
        defaultChannel = https://nixos.org/channels/nixos-unstable;

        # Unnattended upgrades
        autoUpgrade = {
            enable = true;
            channel = https://nixos.org/channels/nixos-unstable;
        };
    };
}
