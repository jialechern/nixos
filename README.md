# NixOS
## 安装系统
### 在 BIOS/UEFI 界面关闭安全启动
### 获取安装引导(Btrfs + NixOS)
下面的任何一种作为安装引导都是可以的:
- "从现有系统安装" 或是 "Host-to-Target 安装"
需要现有系统中具有软件包 `nixos-install-tools`.
- 使用官方提供的 Live CD
在获取 NixOS 官方提供的最小化安装镜像后, 使用如下命令将安装镜像写入 U 盘:
    ```bash,zsh
    sudo dd bs=4M conv=fsync oflag=direct status=progress if=/path/to/nixos.iso of=/dev/sdX && sync
    ```
### 连接网络
1. 如果使用有线网络直接插线即可
2. 使用 wifi
    - 确认 NetworkManager 服务是否已经启用
        ```bash,zsh
        systemctl status NetworkManager
        # 如果未启用则启用它
        sudo systemctl start NetworkManager
        ```
    - 确认 wifi 连接的名称
        ```bash,zsh
        nmcli device wifi list
        ```
    - 找到需要的 SSID 后使用密码连接
        ```bash,zsh
        sudo nmcli device wifi connect <SSID> password <password>
        ```
#### 使用 ssh 进行远程安装
使用 ssh 进行远程安装有着可以 复制/粘贴 命令和错误警告的好处.
1. 修改 root 密码 `sudo passwd root` 当然也可以顺便把当前用户的密码也修改了 `password $USER`
2. 启用 sshd
    ```bash,zsh
    # 查看 sshd 状态
    systemctl status sshd
    # 如果未启用则启用它
    systemctl start sshd
    ```
3. 查看 IP 地址, 并通过局域网内的其它主机进行连接
    ```bash,zsh
    # 在 Live CD 界面获取 IP
    ip addr
    # 在其它主机上进行连接
    ssh root@<IP>
    ```
### 格式化磁盘
1. 确认需要安装的磁盘(一块或是多块) `lsblk`
2. 使用 `fdisk /dev/nvme*n*` 进行分区
    进入交互式界面后可以使用 `m` 获取帮助, 基本只需要用到:
    - `g` 新建 GPT 分区表
    - `p` 查看分区状态
    - `n` 新建分区
    - `t` 设置分区类型, 注意在 NixOS 中引导分区必须通过 `t` 标记为 EFI System 才能安装进 Boot Loader. 可以在 `t` 的交互环境下使用 `L` 查看需要的标记编号.

    **注意:**
        - NixOS 的引导区要大一些(1G 左右), 否则反复构建的过程中产生的世代信息可能会撑爆引导区
        - 交换分区可以选择添加

    下面假设 `nvme0n1p1` 为引导区, `nvme0n1p2` 为根分区且无交换分区.
3. 格式化引导区 `mkfs.fat -F 32 /dev/nvme0n1p1`
4. 格式化根分区(`-L <lable-name>` 标签名任取) `mkfs.btrfs -L nixos /dev/nvme0n1p2`
5. 创建 `Btrfs` 子卷(跨磁盘的话需要将子卷创建在对应的磁盘下)
    ```bash,zsh
    # 先把顶级 Btrfs 分区临时挂载到 /mnt
    mount -t btrfs /dev/nvme0n1p2 /mnt

    # 创建子卷 (业界习惯用 @ 开头来命名子卷)
    btrfs subvolume create /mnt/@          # 用于挂载 / (根目录)
    btrfs subvolume create /mnt/@home      # 用于挂载 /home (用户数据)
    btrfs subvolume create /mnt/@nix       # 用于挂载 /nix (NixOS 的核心仓库)
    btrfs subvolume create /mnt/@log       # 用于挂载 /var/log (系统日志)

    # 创建完子卷后, 把临时挂载点卸载
    umount /mnt
    ```
6. 挂载子卷(如有多块磁盘, 可以跨磁盘挂载)并开启"透明压缩"
    ```bash,zsh
    # 通用挂载选项 (开启 zstd 压缩, 关闭文件访问时间记录以提升性能)
    BTRFS_OPTS="compress=zstd,noatime,discard=async"

    # 挂载根目录子卷
    mount -t btrfs -o subvol=@,$BTRFS_OPTS /dev/nvme0n1p2 /mnt

    # 创建其他挂载点
    mkdir -p /mnt/{home,nix,var/log,boot}

    # 挂载其他子卷
    mount -t btrfs -o subvol=@home,$BTRFS_OPTS /dev/nvme0n1p2 /mnt/home
    mount -t btrfs -o subvol=@nix,$BTRFS_OPTS /dev/nvme0n1p2 /mnt/nix
    mount -t btrfs -o subvol=@log,$BTRFS_OPTS /dev/nvme0n1p2 /mnt/var/log

    # 挂载 EFI 分区
    mount /dev/nvme0n1p1 /mnt/boot
    ```
7. 检查挂载
    - 可以使用 `lsblk -f` 结构化视图的检查挂载
    - 也可以使用 `findmnt -R /mnt` 进行细粒度子卷检查
    - 模拟生成 `NixOS` 配置并打印在命令行上 `nixos-generate-config --root /mnt --show-hardware-config`
8. 生成 `NixOS` 配置 `nixos-generate-config --root /mnt`
    
    **注意:** 使用 "从现有系统安装" 或是 "Host-to-Target 安装" 需要将生成的 `hardware-configuration.nix` 中的多余本机信息删除.
### 安装 NixOS
1. 使用当前这份 `NixOS` 的配置文件, 需要将刚刚生成的 `hardware-configuration.nix` 移动至 `./hosts/<HOSTNAME>/` 下, 并放入配置好的 `configuration.nix`(可以使用当前配置文件中已有的 `configuration.nix` 作为模板)
2. 在 `flake.nix` 的 `nixosConfigurations` 属性集中写入当前主机的配置信息(可以以已有主机作为模板). 在 `modules/*` 中放置了多项现成的可复用的 `configuration.nix` 配置, 只需要按需将它们放入 `nixpkgs.lib.nixosSystem { ... }` 的参数 `modules` 中即可

3. 通过如下命令通过 flake 的方式(前提是已经打开了 flake 功能)安装 `NixOS` 了. 其中 `FLAKEPATH` 是 `flake.nix` 文件的路径, `HOSTNAME` 是 `flake.nix` 中定义好的主机名称.
    ```bash,zsh
    sudo nixos-install --flake <FLAKEPATH>#<HOSTNAME>
    ```

    **本仓库默认配置的一些说明:**
        - niri、nvim、alacritty、ghostty、keepassxc 这些软件的配置是独立的, 构建时需要将它们的配置文件放在 `/etc/nixos/dotfiles` 下并使用和软件相同的名称作为配置文件夹的名称
        也可以使用 `sync-dotfiles.sh` 脚本进行安装, 具体用法见 `sync-dotfiles.sh -h`.
        若想去除这些配置, 只需要将 `home/` 下的同名的 `*.nix` 文件删掉即可
        - 如果不存在 `~/Pictures/Wallpapers/` 目录,
          那么在构建系统时将会自动创建这个路径, 因为这个路径被 niri 配置中的 `awww` 相关自动命令
          作为默认的获取壁纸文件的路径. 如有希望作为壁纸的图片,
          只需要将其存放在该路径下即可.
        - 如果使用核显, 则不应该在 `nixpkgs.lib.nixosSystem { ... }` 的参数 `modules` 中引入形如 `./modules/nvidia.nix` 的独立显卡驱动配置项, 而应当引入形如 `./modules/intel-extra.nix` 这样的核显适配的配置项.

    **网络问题:**
        - 初次构建系统可以使用 `nixos-install.sh` 进行安装, 其中已经包含了初次运行时的国内源设置
        - 部分软件包会因为 hash 对不上而固执的跑到境外网站下载(`modules/system-dependencies-require-proxy.nix`、`home/desktop/applications-require-proxy.nix` 等带有 `*-require-proxy.nix` 字样的文件), 好在这些软件并不影响整体的系统功能, 在第一次 安装/构建 系统是可以将它们移走, 等代理服务能够正常运行后再将它们移入重新构建它们.
        - 私密数据管理模块 `sops-nix` 必须使用透明代理才能够正常构建并使用, 故第一次构建时(如果没有代理)需要将 `sops.nix` 移走. 并且将 `flake.nix` 中的 `inputs` 属性集以及 `outputs` 参数集的 `sops-nix` 相关配置注释, 如下:
        ```nix
        # ...

        inputs = {
            # ...
        
            # # --- --- --- GEGIN 需要注释的部分 --- --- ---
            # # 引入 sops-nix 源
            # sops-nix.url = "github:Mic92/sops-nix";
            # # --- --- --- END   需要注释的部分 --- --- ---

            # ...
        };

        # ...
        
        outputs = {
                    # ...

                    # # --- --- --- GEGIN 需要注释的部分 --- --- ---
                    # sops-nix,
                    # # --- --- --- END   需要注释的部分 --- --- ---

                    # ...
            ... }@inputs:
        
        let
            # ...
        in
        
        { ... }
        ```
        - 也可以使用局域网内的其它主机作为代理(记得开启对应的代理工具的 "允许来自局域网内的连接" 功能)

4. 安装完成后使用 `nixos-enter --root /mnt` 进入刚刚安装的系统, 使用 `passwd <USER>` 修改配置文件中定义好的一般用户的密码(root 用户的密码在安装过程中就会通过交互式的方式设置好)

5. 重启 `reboot`
6. 再次构建前, 如果希望使用存放在配置仓库里的私密数据, 可以将对应的加密密钥存放在 `~/.config/sops/age/keys.txt`
7. 重启后如果 `v2raya` 已经正常开启, 则可以导入节点并开启透明代理, 并将刚刚移出的需要透明代理才可以构建的 nix 配置文件重新放回原本的位置, 并使用 `sudo nixos-rebuild switch --flake <flake.nix-path>#<host-name>` 再次构建
8. `home/dev/opencode/` 下的以及 `home/dev/aider-chat/` 下的配置是私有配置, 不必要时可随时移除.
### 安装交换空间(`Btrfs` 事后补救版)
1. 挂载 `Btrfs` 顶层视图并创建用于交换分区的字卷
    ```zsh,bash
    # 挂载顶级视图
    sudo mount -t btrfs -o subvolid=5 /dev/nvme0n1p2 /mnt
    # 创建子卷
    sudo btrfs subvolume create /mnt/@swap
    # 卸载挂载点
    sudo umount /mnt
    ```
2. 创建用于交换空间的挂载点并挂载字卷
    ```zsh,bash
    sudo mkdir -p /swap
    sudo mount -t btrfs -o noatime,subvol=@swap /dev/nvme0n1p2 /swap
    ```
3. 修改 `hardware-configuration.nix` 以保存 `swap` 挂载信息并启用交换空间
    ```nix
    # hardware-configuration.nix
    # ...
    fileSystems."/swap" = {
      # uuid 可以使用 'lsblk -f` 查询, 也可以照抄同磁盘挂载点的 uuid 配置
      device = "/dev/disk/by-uuid/XXXX-XXXX";
      fsType = "btrfs";
      options = [ "noatime" "subvol=@swap" ];
    };
    # ...
    # --- 启用交换空间 ---
    swapDevices = [{
      device = "/swap/swapfile";
      # 大小可以设置为当前机器内存的 1.5 或是 2.0 倍 (单位: MiB)
      size = 8 * 1024;
    }];
    # ...
    ```
5. 重新复位机器
    ```zsh,bash
    sudo nixos-rebuild switch --flake <flake.nix-path>#<host-name>
    ```
6. 检查交换空间的 开启/使用 情况
    ```zsh,bash
    # 一下两种选其一即可
    swapon --show
    free -h
    ```
### 附录: `Btrfs` 常见操作
1. 查看子卷列表 `sudo btrfs subvolume list /`
2. 操作快照
    ```bash,zsh
    # 瞬间创建快照(写时复制)
    sudo btrfs subvolume snapshot /home /home/home_backup_before_mess
    # 创建只读快照
    sudo btrfs subvolume snapshot -r /home /mnt/snapshots/@home_20260324
    # 删除 子卷/快照(注意: Btrfs 删除子卷不能用 rm -rf)
    sudo btrfs subvolume delete /mnt/snapshots/@home_old
    ```
3. 查看磁盘的真实使用情况 `sudo btrfs filesystem usage /`
4. 简易文件恢复(假设创建了一个快照 `/@home_backup`, 而刚刚不小心删掉了 `~/important.txt`)
    ```bash,zsh
    # 快照在 Btrfs 里就是一个普通的只读文件夹
    # 直接进去拷贝出来即可
    cp /mnt/snapshots/@home_backup/jlc/important.txt ~/important.txt
    ```
5. 系统级全量回滚(如果升级系统后发现完全无法进桌面, 或者误删了重要的系统组件)
    ```bash,zsh
    # 1. 挂载顶级分区
    mount /dev/nvme0n1p2 /mnt -o subvol=/
    # 2. 代替损坏的子卷
    cd /mnt
    # 把坏掉的子卷挪个位置(或者删掉)
    mv @ @_broken
    # 把之前备份的快照变成新的正式子卷
    btrfs subvolume snapshot snapshots/@_backup @
    # 重启: 此时系统会加载那个完好的 @ 快照, 仿佛一切都没发生过
    ```
6. 文件自检(Btrfs 会存储数据的校验和, 如果怀疑硬盘有坏道或数据腐烂(Bitrot)可以自检)
    ```bash,zsh
    sudo btrfs scrub start /
    # 查看进度
    sudo btrfs scrub status /
    ```
7. Balance(负载均衡, 通常在单盘上不需要, 但如果发现物理空间明明很大, 却提示空间不足, 可能需要整理一下) `sudo btrfs balance start /`
