{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "ntfs" ];

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };
  nixpkgs.config.chromium.commandLineArgs = "--disable-features=UseChromeOSDirectVideoDecoder";

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
    ];
  };

  nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
  system.autoUpgrade.enable = true;
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "Equinox";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = {
    LC_CTYPE="zh_CN.UTF-8";
    LC_NUMERIC="zh_CN.UTF-8";
    LC_TIME="zh_CN.UTF-8";
    LC_COLLATE="zh_CN.UTF-8";
    LC_MONETARY="zh_CN.UTF-8";
    LC_MESSAGES="zh_CN.UTF-8";
    LC_PAPER="zh_CN.UTF-8";
    LC_NAME="zh_CN.UTF-8";
    LC_ADDRESS="zh_CN.UTF-8";
    LC_TELEPHONE="zh_CN.UTF-8";
    LC_MEASUREMENT="zh_CN.UTF-8";
    LC_IDENTIFICATION="zh_CN.UTF-8";
  };
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-chinese-addons
      fcitx5-mozc
    ];
  };

  fonts = {
    enableDefaultFonts = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [
          "Hack"
          "Source Han Mono SC"
        ];
        sansSerif = [
          "Inter"
          "Liberation Sans"
          "Source Han Sans SC"
        ];
        serif = [
          "Liberation Serif"
          "Source Han Serif SC"
        ];
      };
    };
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      hack-font
      inter
      liberation_ttf
      noto-fonts-emoji
      roboto
      sarasa-gothic
      source-han-mono
      source-han-sans
      source-han-serif
      wqy_microhei
      wqy_zenhei
    ];
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;


  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "sakura";
  services.xserver.desktopManager.plasma5.excludePackages = with pkgs; [
    elisa
    okular
    khelpcenter
  ];

  # Configure keymap in X11
  services.xserver.layout = "us";

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sakura = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [ 
 
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    nix-index
    filezilla
    chromium
    konsole
    git
    screen
    clash
    vscode
    vlc
    intel-gpu-tools
    nur.repos.xddxdd.qq
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [ 12520];
  services.openssh.forwardX11 = true;
  services.samba = {
    enable = true;
    openFirewall = true;
    shares = {
      myshare = {
        path = "/home/sakura";
        "valid users" = "sakura";
        public = "no";
        writeable = "yes";
        printable = "no";
        "create mask" = "0765";
      };
    };
  };
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 12520 ];
  networking.firewall.allowedUDPPorts = [ 12520 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
