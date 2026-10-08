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
1. 修改 root 密码 `sudo passwd root` 当然也可以顺便把当前用户的密码也修改了 `passwd $USER`
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
    # 通用挂载选项: zstd 压缩 + 自动碎片整理 + 异步 discard
    # (与 hosts/common.nix 追加上去的挂载选项一致; 设备/子卷声明在 hw-cfg,
    #  /swap 子卷另加 noatime, 见下文)
    BTRFS_OPTS="compress=zstd,autodefrag,discard=async"

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
1. 使用当前这份 `NixOS` 的配置文件, 需要将刚刚生成的 `hardware-configuration.nix` 移动至 `./hosts/<HOSTNAME>/` 下, 并放入配置好的 `configuration.nix`(可参考已有主机: 只 import `../common.nix` 与 hw-cfg 并设置 `networking.hostName` 即可; 两机共用的用户/组、挂载选项、stateVersion 都在 `hosts/common.nix` —— 新机器若初始安装版本与 25.11 不同, 在本机配置里直接写 `system.stateVersion` 即可覆盖它)
2. 在 `flake.nix` 的 `nixosConfigurations` 属性集中写入当前主机的配置信息(可以以已有主机作为模板). 在 `modules/*` 中放置了多项现成的可复用的 `configuration.nix` 配置, 只需要按需将它们放入 `nixpkgs.lib.nixosSystem { ... }` 的参数 `modules` 中即可

3. 通过如下命令通过 flake 的方式(前提是已经打开了 flake 功能)安装 `NixOS` 了. 其中 `FLAKEPATH` 是 `flake.nix` 文件的路径, `HOSTNAME` 是 `flake.nix` 中定义好的主机名称.
    ```bash,zsh
    sudo nixos-install --flake <FLAKEPATH>#<HOSTNAME>
    ```

    **本仓库默认配置的一些说明:**
        - nvim 的配置已并入本仓库的 `home/shell/nvim/`, 由 `home/shell/nvim.nix` 在构建期校验(全部 lua 跑 `luajit -bl`, 失败则构建失败)后以逐文件软链方式部署到 `~/.config/nvim/`(只读软链, 改完需重建; 新增文件要先 `git add`, 否则 flake 看不见); 另有 tmpfiles 创建的可写热调试文件 `~/.config/nvim/after/plugin/local-live.lua`(不在本仓库/flake 里, 不随 rebuild 部署, 改完用 `:luafile %` 或 `:restart` 生效); niri 的配置已并入本仓库的 `home/desktop/niri/`, 由 `home/desktop/niri.nix` 以逐文件软链方式部署到 `~/.config/niri/`(只读软链, 改完需重建), 其中 `conf.d/local-override.kdl` 由该模块按主机生成, 不要手写同名文件放回仓库(`home/desktop/niri.nix` 有构建期断言拦截); keepassxc 的配置不入本仓库, 本仓库只负责安装软件与运行时依赖(`home/desktop/applications.nix`), `~/.config/keepassxc/` 由本地手动维护。
        - 可选模块由 `builtins.pathExists` 做开关(如 `home/desktop.nix`、`sops.nix`、`modules/system-dependencies-require-proxy.nix`)。flake 只包含 git 已索引的文件, 所以**新增这类开关文件后必须先 `git add`**, 否则开关静默为 false、模块不会生效(Nix 手册 `nix flake` 一节: "files which are matched by .gitignore or have never been git add-ed will not be available in the flake"); `modules/nix-config.nix` 的 `warn-dirty = false` 又关掉了脏树提示, 因此不会有任何警告。
        - 壁纸目录为 `~/Wallpapers/`, 不再由 flake 输入提供 (也不再是软链), 而是由 `home.nix` 的 `xdg.userDirs.extraConfig.WALLPAPERS` 声明, 并由 `createDirectories = true` 在构建时自动创建; niri 的启动项与快捷键以该路径为默认壁纸目录 (递归其全部子目录), 壁纸图片由用户自行存放在该路径下.
        - 如果使用核显, 则不应该在 `nixpkgs.lib.nixosSystem { ... }` 的参数 `modules` 中引入形如 `./modules/nvidia.nix` 的独立显卡驱动配置项, 而应当引入形如 `./modules/intel-extra.nix` 这样的核显适配的配置项. 这条约定现在由 `modules.nix` 的 `machine.gpu.driver` 选项在求值期把关(两个 GPU 模块同现即报错, 新主机漏加 GPU 模块也会被断言拦住).
        - pi 的配置由 `home/shell/pi.nix` 以 `builtins.toJSON` 生成, 并部署为指向 Nix store 的只读软链 (如 `~/.pi/agent/config.json`), 所以改配置必须重新构建才生效; 其中 `packages` 里的 npm 扩展在 pi 首次启动时联网安装到 `~/.pi/agent/npm/`, **不在 Nix store 里**, 因此不受 `flake.lock` 约束 (上游发新版即跟随变化).

    **网络问题:**
        - 初次构建系统可以使用 `nixos-install.sh` 进行安装, 其中已经包含了初次运行时的国内源设置
        - 部分软件包会固执地从境外站点下载 (`modules/system-dependencies-require-proxy.nix`、`home/desktop/applications-require-proxy.nix` 等带 `*-require-proxy.nix` 字样的文件) —— 这些都不影响系统主功能, 第一次 安装/构建 时可以把它们一并移走, 等代理可用后再放回并重新构建.
        - `pi` 同样依赖外网: 它的 flake input 来自 GitHub (`flake.nix` 里的 `pi`), 构建期还要从 `pi.dev` 拉取固定输出的 model catalog 与 npm tarball. 无代理首装时把 `home/shell.nix` 里的 `./shell/pi.nix` 注释掉, 并按下面 `sops-nix` 的同样做法注释 `flake.nix` 中 `pi` 的 input 与 outputs 参数 —— 这样只是不安装 pi, 系统其余部分照常.
        - 私密数据管理模块 `sops-nix` 必须使用透明代理才能够正常构建并使用, 故第一次构建时(如果没有代理)需要将 `sops.nix` 移走. 并且将 `flake.nix` 中的 `inputs` 属性集以及 `outputs` 参数集的 `sops-nix` 相关配置注释, 如下:
        ```nix
        # ...

        inputs = {
            # ...
        
            # # --- --- --- BEGIN 需要注释的部分 --- --- ---
            # # 引入 sops-nix 源
            # sops-nix = {
            #   url = "github:Mic92/sops-nix";
            #   inputs.nixpkgs.follows = "nixpkgs";
            # };
            # # --- --- --- END   需要注释的部分 --- --- ---

            # ...
        };

        # ...
        
        outputs = {
                    # ...

                    # # --- --- --- BEGIN 需要注释的部分 --- --- ---
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
6. 再次构建前, 如果希望使用存放在配置仓库里的私密数据, 可以将对应的加密密钥存放在 `~/.config/sops/age/keys.txt`. 该私钥由 `age-keygen` 生成(流程见 `.sops.yaml` 顶部注释), 应当**离线备份** —— 仓库里只有公钥, 它一旦丢失, `secrets/` 里的密文就无法恢复; 轮换密钥 = `age-keygen -o new.key` → 把新公钥写进 `.sops.yaml` → `sops updatekeys secrets/**`
7. 重启后如果 `v2raya` 已经正常开启, 则可以导入节点并开启透明代理, 并将刚刚移出的需要透明代理才可以构建的 nix 配置文件重新放回原本的位置, 并使用 `sudo nixos-rebuild switch --flake <flake.nix-path>#<host-name>` 再次构建
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
3. 保存 `swap` 挂载信息并启用交换空间 (本仓库与其它子卷声明一起放在 `hardware-configuration.nix`; 也可写进 `hosts/<HOSTNAME>/configuration.nix`, 两者按 attr/list 合并)
    ```nix
    # hardware-configuration.nix (或 hosts/<HOSTNAME>/configuration.nix)
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
    **注意:** `hardware-configuration.nix` 是 `nixos-generate-config` 生成的 (文件头写着 "Do not modify this file!"), 再次运行生成器会覆盖手改内容。因此长期维护策略是: 存储布局 (device/fsType/subvol) 以该文件为准, 而**追加的挂载选项** (如压缩) 写在 `hosts/common.nix` 的 `fileSystems."/".options` 里 —— 选项按 list 合并, 重新生成 hw-cfg 也不会丢; swap 这两段放哪边都行, 本仓库与其它子卷声明一起放在 hw-cfg。

4. 重新构建以应用(交换文件由上游用 `btrfs filesystem mkswapfile` 自动创建, 无需手工 mkswap/chattr)
    ```zsh,bash
    sudo nixos-rebuild switch --flake <flake.nix-path>#<host-name>
    ```
5. 检查交换空间的 开启/使用 情况
    ```zsh,bash
    # 以下两种选其一即可
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
4. 简易文件恢复(假设事先做过 home 子卷快照 `@home_20260324`, 而刚刚不小心删掉了 `~/important.txt`)
    ```bash,zsh
    # 快照在 Btrfs 里就是一个普通的只读文件夹
    # 直接进去拷贝出来即可
    cp /mnt/snapshots/@home_20260324/jlc/important.txt ~/important.txt
    ```
5. 系统级全量回滚(如果升级系统后发现完全无法进桌面, 或者误删了重要的系统组件)
    ```bash,zsh
    # 1. 挂载顶级分区
    mount /dev/nvme0n1p2 /mnt -o subvol=/
    # 2. 代替损坏的子卷
    cd /mnt
    # 把坏掉的子卷挪个位置(或者删掉)
    mv @ @_broken
    # 把之前备份的快照变成新的正式子卷 (前提: 事先做过根子卷快照, 例如
    # `sudo btrfs subvolume snapshot -r / /mnt/snapshots/@root_backup`)
    btrfs subvolume snapshot snapshots/@root_backup @
    # 重启: 此时系统会加载那个完好的 @ 快照, 仿佛一切都没发生过
    ```
6. 文件自检(Btrfs 会存储数据的校验和, 如果怀疑硬盘有坏道或数据腐烂(Bitrot)可以自检)
    ```bash,zsh
    sudo btrfs scrub start /
    # 查看进度
    sudo btrfs scrub status /
    ```
7. Balance(负载均衡, 通常在单盘上不需要, 但如果发现物理空间明明很大, 却提示空间不足, 可能需要整理一下) `sudo btrfs balance start /`
