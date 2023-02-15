# 0. RTFM

- [manual](https://nixos.org/manual/nixos/stable/)
- [wiki](https://nixos.wiki/wiki/)
- [packages](https://search.nixos.org/packages)
- [options](https://search.nixos.org/options)
- [FAQ](https://github.com/nixos-cn/NixOS-FAQ)

# 1. 基本操作

- 安装命令
  
  `parted /dev/sda`

  `mklabel gpt`
  
  `mkpart primary 512MB 100%`

  `mkpart ESP fat32 1MB 512MB`

  `set 2 esp on`

  (ctrl+c)

  `mkfs.ext4 -L nixos /dev/sda1`

  `mkfs.fat -F 32 -n boot /dev/sda2`
  
  `mount /dev/disk/by-label/nixos /mnt`

  `mkdir -p /mnt/boot`

  `mount /dev/disk/by-label/boot /mnt/boot`

  `nixos-generate-config --root /mnt`

  `nano /mnt/etc/nixos/configuration.nix`

  `nixos-install`
  
  `reboot`

- `/etc/nixos/configuration.nix`: 系统配置文件
- `sudo nixos-rebuild switch`: 更新配置，尽量在当前系统中实现更新，将新版本设为启动首选项。
- `sudo nixos-rebuild test`: 更新配置，尽量在当前系统中实现更新，但不将新版本设为启动首选项，以便重启恢复原样。
- `sudo nixos-rebuild boot`: 更新配置，不在当前系统中更新，但将新版本设为启动首选项。
- `sudo nixos-rebuild build`: 不更新配置，仅测试是否可以正常编译。
- `sudo nixos-rebuild switch --option substituters "https://mirror.tuna.tsinghua.edu.cn/nix-channels/store"`: 立刻、临时启用其他二进制缓存源。
- `sudo nixos-rebuild switch --upgrade`: 系统升级。
- 回收磁盘空间：假设要保留最近3次构建的nixos版本

  `sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +3`

  `nix-collect-garbage`

  然后再`sudo nixos-rebuild boot`即可。

  另外也可按时间自动清理磁盘，详见[manual](https://nixos.org/manual/nixos/stable/index.html#sec-nix-gc)。
- `sudo nix-store --add-fixed sha256 <path>`: 手动下载文件，然后使用该命令加入nix store，避免nixos-rebuild因网络问题失败。

# 2. 换源

使用[清华大学的镜像](https://mirrors.tuna.tsinghua.edu.cn/help/nix/)来加快安装速度。

- Nixpkgs二进制缓存
  
  ```
  nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
  ```

- Nixpkgs channel
  
  在命令行中敲入

  `sudo nix-channel --add https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-22.11 nixos`
  
  `sudo nix-channel --update`

  注意将**22.11**更换为当前系统版本号，否则可能无法正常rebuild。

同时为了允许vscode等非自由软件安装，设置

```
nixpkgs.config.allowUnfree = true;
```

- `sudo nix-channel --list | grep nixos`: 查看当前channel。注意root和普通用户是不一样的。
- 自动升级：

  ```
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  ``` 

  如果不设置**allowReboot**，则相当于自动定期执行`nixos-rebuild switch --upgrade`，在内核更新时不会自动重启。

# 3. [NUR](https://github.com/nix-community/NUR)

以Linux QQ为例，可以找到[别人打包好的文件](https://github.com/nix-community/nur-combined/tree/master/repos/xddxdd/pkgs/uncategorized/qq)，是用户xddxdd的qq包，于是

```
# 添加nur源
nixpkgs.config.packageOverrides = pkgs: {
  nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
  };
};

# 添加qq包
environment.systemPackages = with pkgs; [
  nur.repos.xddxdd.qq
];
```

使用这种方式可能拖慢未来nixos-rebuild的速度，届时需要使用http_proxy等方法。

# 4. Intel Alder Lake 核显问题

系统[默认使用](https://nixos.wiki/wiki/Linux_kernel)的内核是最新的LTS内核，可能尚未兼容UHD700系列的核显，需要设置

```
boot.kernelPackages = pkgs.linuxPackages_latest;
```

才能正常进入桌面。



# 5. 桌面

使用sddm + kde桌面：

```
services.xserver.enable = true;
services.xserver.displayManager.sddm.enable = true;
services.xserver.displayManager.autoLogin.enable = true;
services.xserver.displayManager.autoLogin.user = "alice";  # 注意修改用户名
services.xserver.desktopManager.plasma5.enable = true;
services.xserver.desktopManager.plasma5.excludePackages = with pkgs; [  # 剔除不喜欢的包
  elisa
  okular
  khelpcenter
];
```

如果不喜欢KWalletManager，可以在plasma5桌面设置中禁用。另：12代酷睿核显[硬解视频](https://nixos.wiki/wiki/Accelerated_Video_Playback)
```
nixpkgs.config.chromium.commandLineArgs = "--disable-features=UseChromeOSDirectVideoDecoder";
hardware.opengl = {
  enable = true;
  extraPackages = with pkgs; [
    intel-media-driver # LIBVA_DRIVER_NAME=iHD
  ];
};
```

其他设置：
- 不自动锁屏：系统设置->工作区行为->锁屏
- 设置numlock键：系统设置->输入设备->键盘->Hardware->Turn on->应用

# 5. 本地化与输入法

使用fcitx5 + chinese-addons进行输入，日语输入法为mozc，配置如下

```
i18n.defaultLocale = "en_US.UTF-8";  # Arch的习惯，但似乎更多人使用zh_CN。如果在这里使用en_US，进入KDE之后需要修改语言。
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
```

字体参考[bobby285271](https://github.com/bobby285271/nixos-config/blob/master/desktop/fonts.nix)
```
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
```

# 6. 网络配置

```
networking.networkmanager.enable = true;
users.users.alice.extraGroups = [ "networkmanager" ];  # 这条不是新增的，是在extraGroups里面加入networkmanager。注意这里的用户是alice。
```

- `nmcli connection show`: 显示连接列表及其名称、UUID、类型和支持设备；
- `nmcli connection up name或uuid`: 激活连接(即使用现有配置文件连接到网络)；
- `nmcli device`: 显示所有网络设备及其状态；
- `nmcli device wifi list`: 显示附近的wifi网络；
- `nmcli device wifi connect SSID或BSSID password 密码`: 连接到wifi网络；
- `nmcli radio wifi off`: 关闭wifi。

创建后有三种方法可以配置连接，配置完需使用`nmcli connection reload`重载配置文件：
- nmcli 交互式编辑器: `nmcli connection edit 连接名`
- nmcli 命令行界面: `nmcli connection modify 连接名 setting.property value`
- 在 /etc/NetworkManager/system-connections/ 中修改对应的文件

如果没有无线网卡设备，可能是因为没有启动**wpa_supplicant**服务。也许重启系统比systemctl start更合适。

# 7. 远程访问

- OpenSSH
  ```
  services.openssh.enable = true;
  services.openssh.ports = [11451];  # 修改端口
  services.openssh.settings.X11forwarding = true;  # 允许使用图形化程序

  networking.firewall.allowedTCPPorts = [11451];  # 防火墙
  networking.firewall.allowedUDPPorts = [11451];
  ```

- Samba
  ```
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
  ```

  这里sakura是我的用户名。在命令行输入`sudo smbpasswd -a sakura`来为该用户设置samba密码。

- VSCode

  vscode的nodejs和nixos存在某种冲突，无法远程连上nixos后使用。解决方法如下：

  1. 使用vscode连接一次nixos，确保`~/.vscode-server`文件夹被创建；
  2. 安装nodejs
     ```
     environment.systemPackages = with pkgs; [
       nodejs 
     ];
     ```
  3. 替换vscode的nodejs

     `cd ~/.vscode-server/bin/*/`

     `rm node`
     
     `ln -s $(which node)`
  

# 8. 挂载硬盘

```
boot.supportedFilesystems = [ "ntfs" ];  # 使用ntfs-3g支持

fileSystems."/path/to/mount/to" =
  { device = "/path/to/the/device";
    fsType = "ntfs3"; 
    options = [ "rw" "uid=theUidOfYourUser"];
  };

fileSystems."/data" =
  { device = "/dev/disk/by-label/data";
    fsType = "ext4";
  };
```

# 9. 其他有用的安装包

```
environment.systemPackages = with pkgs; [
  wget
  nix-index  # 文件查找
  filezilla  # sftp文件传输
  chromium  # 浏览器
  konsole  # 终端
  git
  screen
  clash
  vscode
  intel-gpu-tools  # intel gpu监控程序，判断视频是否硬解
  vlc  # 音乐播放
];
```

- git配置用户和电子邮箱：

  `git config --global user.name "sakura"`

  `git config --global user.email "brynhild@pku.edu.cn"`

- intel-gpu-tools的调用命令是`sudo intel_gpu_top`
- nix-index的使用命令是`nix-locate`