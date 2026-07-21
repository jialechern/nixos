{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # 核心工具链
    rustc

    # 额外组件
    rustfmt
    clippy
    cargo-flamegraph
    cargo-bloat
    cargo-llvm-lines

    # rust-src 用于 IDE 自动补全和跳转定义
    (pkgs.runCommand "rust-src" { } ''
      mkdir -p $out/lib/rustlib/src
      ln -s ${pkgs.rustPlatform.rustcSrc} $out/lib/rustlib/src/rust
    '')

    # 可选: 常用的 cargo 扩展
    cargo-edit # cargo add/rm/upgrade
    cargo-watch # 文件变化自动重新编译
    cargo-audit # 安全漏洞扫描
  ];

  # =========================================================================
  # Cargo (Rust 包管理器) 全局配置
  # 通过 Home Manager 管理 $CARGO_HOME/config.toml
  # 参考: https://doc.rust-lang.org/cargo/reference/config.html
  # =========================================================================

  programs.cargo = {
    # ---------------------------------------------------------------------
    # 是否启用 Home Manager 对 Cargo 配置的管理
    # 启用后会将 settings 中的配置写入 $CARGO_HOME/config.toml
    # ---------------------------------------------------------------------
    enable = true;

    # ---------------------------------------------------------------------
    # 指定要安装的 Cargo 软件包
    # null 表示不通过 Home Manager 安装(自己通过 rustup 或系统包管理安装)
    # 如果设为 pkgs.cargo 则会安装 nixpkgs 提供的 cargo
    # ---------------------------------------------------------------------
    package = pkgs.cargo;

    # ---------------------------------------------------------------------
    # 自定义 CARGO_HOME 目录
    # 默认 null 使用 ${config.home.homeDirectory}/.cargo
    # 示例: "${config.xdg.dataHome}/cargo" -> ${config.xdg.dataHome}/cargo
    # 设置后会自动导出 CARGO_HOME 环境变量
    # ---------------------------------------------------------------------
    cargoHome = null;

    # =========================================================================
    # Cargo 配置项 (写入 $CARGO_HOME/config.toml)
    # 各配置节与 Cargo 官方文档一一对应
    # =========================================================================
    settings = {
      # =====================================================================
      # 1. [alias] — 命令别名
      # 定义 cargo 子命令的简写或组合别名
      # 别名可以递归嵌套
      # =====================================================================
      alias = {
        # # 内置别名 (Cargo 默认提供)
        # b = "build"    # cargo b 等价于 cargo build
        # c = "check"    # cargo c 等价于 cargo check
        # t = "test"     # cargo t 等价于 cargo test
        # r = "run"      # cargo r 等价于 cargo run
        # d = "doc"      # cargo d 等价于 cargo doc
        # rm = "remove"  # cargo rm 等价于 cargo remove

        # --- 自定义别名 ---
        # 以 release 模式运行
        rr = "run --release";

        # 快速检查所有目标(lib, bin, test, example 等)
        ca = "check --all-targets";

        # 以 release 模式检查
        cr = "check --release";

        # 构建并运行特定示例(使用数组形式, 避免空格解析问题)
        re = [ "run" "--example" ];

        # 使用 nextest 运行测试(需安装 cargo-nextest)
        nt = "nextest run";

        # 使用 nextest 运行所有测试
        nta = "nextest run --all-targets";

        # 更新单个依赖
        up = "update";

        # # 修复 clippy 警告(需 nightly)
        # fix = "clippy --fix --allow-dirty";
      };

      # =====================================================================
      # 2. [build] — 构建行为与编译器设置
      # 控制编译并行度、目标平台、输出目录、rustc/rustdoc 标志等
      # =====================================================================
      build = {
        # --- 并行编译任务数 ---
        # 设为 CPU 核心数以充分利用多核性能
        # 负数表示 "逻辑 CPU 数 + 该值"(如 -1 表示少用一个核)
        # 字符串 "default" 恢复默认值
        jobs = "default";

        # --- rustc 编译器路径 ---
        # 通常无需设置，Cargo 会自动查找
        # rustc = "rustc";

        # --- rustc 包装器 ---
        # 在 rustc 之前执行的包装程序(如 sccache 缓存编译器输出)
        # 第一个参数是 rustc 的实际路径
        # rustc-wrapper = "sccache";

        # --- rustc 工作区包装器 ---
        # 仅对工作区成员生效的 rustc 包装器, 与 rustc-wrapper 可嵌套
        # rustc-workspace-wrapper = "...";

        # --- rustdoc 路径 ---
        # rustdoc = "rustdoc";

        # --- 默认编译目标平台 ---
        # 单个目标平台三元组字符串
        # target = "x86_64-unknown-linux-gnu";
        # 多个目标（注意：此设置对 cargo install 无效）
        # target = [ "x86_64-unknown-linux-gnu" "wasm32-unknown-unknown" ];

        # --- 编译产物输出目录 ---
        # 相对于工作区根目录，默认为 "target"
        # target-dir = "target";

        # --- 中间编译产物目录 ---
        # 支持模板变量: {workspace-root}, {cargo-cache-home}, {workspace-path-hash}
        # 默认等于 target-dir
        # build-dir = "target";

        # --- 传递给 rustc 的额外标志 ---
        # 用于全局启用特定编译器选项
        # 数组形式（推荐，避免空格分割歧义）
        # rustflags = [
        #   "-C" "target-cpu=native"  # 针对本机 CPU 优化
        #   "-C" "link-arg=-fuse-ld=mold"  # 使用 mold 链接器（更快）
        # ];
        # 或字符串形式
        # rustflags = "-C target-cpu=native";

        # --- 传递给 rustdoc 的额外标志 ---
        # rustdocflags = ["--document-private-items"];

        # --- 增量编译 ---
        # true 启用(加快重新编译速度), false 禁用
        # 默认从 profile 继承
        # incremental = true;

        # --- 依赖信息文件的基础路径剥离 ---
        # 将绝对路径转为相对路径, 方便工具链处理
        # dep-info-basedir = ".";
      };

      # =====================================================================
      # 3. [doc] — 文档生成设置
      # =====================================================================
      doc = {
        # --- cargo doc --open 使用的浏览器 ---
        # 覆盖 BROWSER 环境变量
        # 数组形式或空格分隔的字符串形式均可
        # browser = "firefox";
        # browser = [ "google-chrome-stable" "--new-window" ];
      };

      # =====================================================================
      # 4. [env] — 构建时环境变量
      # 为 build.rs 脚本、rustc 调用、cargo run/build 设置环境变量
      # 默认不覆盖已有环境变量，设置 force = true 可强制覆盖
      # relative = true 表示相对于 .cargo 目录父目录的路径
      # =====================================================================
      env = {
        # 示例：指定 OpenSSL 路径
        # OPENSSL_DIR = "/usr/local/opt/openssl";

        # 使用表格形式指定更多选项:
        # OPENSSL_DIR = { value = "/usr/local/opt/openssl"; force = true; };
        # OPENSSL_DIR = { value = "vendor/openssl"; relative = true; };
      };

      # =====================================================================
      # 5. [future-incompat-report] — 未来不兼容报告
      # =====================================================================
      future-incompat-report = {
        # --- 报告显示频率 ---
        # "always": 每次产生未来不兼容报告都显示通知(默认)
        # "never": 从不显示通知
        frequency = "always";
      };

      # =====================================================================
      # 6. [cache] — 缓存管理
      # Cargo 会自动清理长期未使用的缓存文件
      # 网络下载的文件 3 个月未使用会被清理
      # 无需网络可生成的 1 个月未使用会被清理
      # =====================================================================
      cache = {
        # --- 自动清理频率 ---
        # 可选值: "never" (从不) / "always" (每次运行)
        #         / "<数字> <单位>" 如 "1 day", "2 weeks", "1 month"
        # 注意: 这不是文件清理的年龄阈值，而是检查清理的频率
        auto-clean-frequency = "1 day";
      };

      # =====================================================================
      # 7. [cargo-new] — cargo new 默认设置
      # =====================================================================
      cargo-new = {
        # --- 新项目版本控制系统 ---
        # 可选值: "git" (默认), "hg" (Mercurial), "pijul", "fossil", "none"
        # 如果当前已在 VCS 仓库中，默认值为 "none"
        vcs = "git";
      };

      # =====================================================================
      # 8. [http] — HTTP 网络设置
      # 控制下载 crate 依赖和访问远程 git 仓库的 HTTP 行为
      # =====================================================================
      http = {
        # --- HTTP 调试开关 ---
        # 开启后配合 CARGO_LOG=network=debug 可查看 HTTP 请求详情
        # 警告: 日志可能包含认证 token, 公开发布前务必审查
        # debug = false;

        # --- HTTP(S) 代理 ---
        # 格式: [protocol://]host[:port] (libcurl 格式)
        # 也可设置环境变量 HTTPS_PROXY / https_proxy / http_proxy
        # proxy = "http://127.0.0.1:7890";

        # --- 请求超时（秒） ---
        timeout = 60; # 增大默认超时, 避免下载大文件时超时

        # --- 慢速传输阈值(字节/秒) ---
        # 在 timeout 秒内平均速度低于此值则认为连接太慢, 中断并重试
        low-speed-limit = 10;

        # --- 自定义 User-Agent ---
        # 默认包含 Cargo 的版本信息
        # user-agent = "custom-user-agent";

        # --- HTTP/2 多路复用 ---
        # true 启用(默认), 多个请求共享同一连接, 显著提升下载性能
        multiplexing = true;

        # --- TLS 版本 ---
        # 单字符串形式设置最低版本: "tlsv1.0", "tlsv1.1", "tlsv1.2", "tlsv1.3"
        # 或者使用 min/max 表格形式:
        # ssl-version = { min = "tlsv1.2"; max = "tlsv1.3"; };

        # --- CA 证书包路径 ---
        # 用于 TLS 证书验证, 默认使用系统证书
        # cainfo = "/etc/ssl/certs/ca-certificates.crt";

        # --- 代理 CA 证书包路径 ---
        # 默认回退到 http.cainfo
        # proxy-cainfo = "/path/to/proxy-ca-bundle.crt";

        # --- 检查 TLS 证书吊销 ---
        # 仅 Windows 有效, Linux 上无需设置
        # check-revoke = false;
      };

      # =====================================================================
      # 9. [net] — 网络连接设置
      # =====================================================================
      net = {
        # --- 网络错误重试次数 ---
        retry = 5; # 增加重试次数以应对不稳定网络

        # --- 使用 git CLI 执行 fetch ---
        # true: 使用系统 git 命令获取索引和依赖(适合需要特殊认证的场景)
        # false: 使用内置 git 库(默认)
        git-fetch-with-cli = false;

        # --- 离线模式 ---
        # true: 不访问网络, 仅使用本地缓存
        # 可用 --offline 命令行选项覆盖
        # offline = false;

        # --- SSH 已知主机密钥 ---
        # Cargo 内置了 github.com 的主机密钥
        # 格式: "主机名 密钥类型 base64密钥"
        ssh = {
          # known-hosts = [
          #   "gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf"
          # ];
        };
      };

      # =====================================================================
      # 10. [registry] — 默认注册表设置
      # =====================================================================
      registry = {
        # --- 默认注册表名称 ---
        # 用于 cargo publish 等命令, 默认 "crates-io"
        default = "crates-io";

        # --- 全局凭证提供者 ---
        # 列表越靠后优先级越高, 默认 ["cargo:token"]
        global-credential-providers = [ "cargo:token" ];

        # --- 注意 ---
        # token 和 credential-provider 等敏感信息应放在
        # $CARGO_HOME/credentials.toml (由 cargo login 自动管理)
        # 不要在 config.toml 中明文存放 token
      };

      # =====================================================================
      # 11. [registries] — 额外注册表配置
      # crates.io 及第三方注册表
      # =====================================================================
      registries = {
        # --- crates.io 专用配置 ---
        "crates-io" = {
          # 访问协议
          # "sparse": 使用 HTTPS 稀疏索引(默认, 性能更优)
          # "git": 克隆整个 crates.io 索引(速度慢, 占用大)
          protocol = "sparse";
        };

        # --- 第三方注册表示例 ---
        # my-registry = {
        #   index = "https://my-registry.example.com/index";
        #   # token 应放在 credentials.toml 中
        # };
      };

      # =====================================================================
      # 12. [resolver] — 依赖解析行为
      # =====================================================================
      resolver = {
        # --- 不兼容 Rust 版本的依赖处理 ---
        # "allow": 与普通版本一视同仁
        # "fallback": 仅在找不到兼容版本时才考虑(1.84+)
        # 可用 --ignore-rust-version 命令行选项覆盖
        incompatible-rust-versions = "allow";
      };

      # =====================================================================
      # 13. [profile] — 编译配置文件(profile)覆盖
      # 全局修改 profile 设置, 覆盖 Cargo.toml 中的定义
      # 支持 dev, release, test, bench 及自定义 profile
      # =====================================================================
      profile = {
        # --- 开发(dev)profile ---
        # 默认优化级别 0, 快速编译
        dev = {
          # 优化级别: 0 (无), 1, 2, 3, "s" (体积), "z" (极致体积)
          opt-level = 0;

          # 调试信息: 0 (无), 1 (行号表), 2 (完整) / true = 2, false = 0
          debug = true;

          # 调试信息分割: "off", "packed", "unpacked"
          # split-debuginfo = "unpacked";

          # 剥离符号: "none", "debuginfo", "symbols" / true, false
          # strip = "none";

          # 调试断言
          debug-assertions = true;

          # 整数溢出检查
          overflow-checks = true;

          # 增量编译
          incremental = true;

          # LTO(链接时优化): false, true, "thin", "fat", "off"
          lto = false;

          # panic 策略: "unwind" (展开), "abort" (直接中止)
          panic = "unwind";

          # 代码生成单元数(并行编译粒度)
          codegen-units = 256;

          # rpath 链接选项(设置可执行文件中的动态库搜索路径)
          # rpath = false;

          # --- 覆盖构建脚本的 profile ---
          # build-override = {
          #   opt-level = 0;
          #   debug = false;
          # };

          # --- 覆盖特定包的 profile ---
          # package = {
          #   "some-crate" = {
          #     opt-level = 3;
          #   };
          # };
        };

        # --- 发布(release)profile ---
        release = {
          opt-level = 3; # 最高优化级别
          debug = false;
          debug-assertions = false;
          overflow-checks = false;
          lto = false; # true 可启用全 LTO 以获得更小/更快的二进制文件
          panic = "unwind";
          incremental = false;
          codegen-units = 16; # 较小值可产生更好优化，但编译更慢；1 为最佳但最慢
          # strip = "symbols"; # 剥离符号以减小二进制体积
        };

        # --- 测试(test)profile ---
        # 继承自 dev profile，可单独覆盖
        test = {
          opt-level = 0;
          debug = 2; # 测试时建议保留完整调试信息
        };

        # --- 基准测试(bench)profile ---
        # 继承自 release profile, 可单独覆盖
        bench = {
          opt-level = 3;
          debug = false;
        };
      };

      # =====================================================================
      # 14. [term] — 终端输出设置
      # 控制 Cargo 的终端输出行为和美化
      # =====================================================================
      term = {
        # --- 安静模式 ---
        # true 不输出日志消息(--quiet 可覆盖)
        # quiet = false;

        # --- 详细模式 ---
        # true 输出额外详细信息(--verbose 可覆盖)
        # verbose = false;

        # --- 彩色输出 ---
        # "auto": 自动检测终端是否支持彩色(默认)
        # "always": 始终使用彩色
        # "never": 禁用彩色
        color = "auto";

        # --- 终端超链接 ---
        # 是否在输出中插入可点击的超链接(需终端支持)
        hyperlinks = true;

        # --- Unicode 字符 ---
        # 是否允许输出非 ASCII Unicode 字符(如进度条字符)
        unicode = true;

        # --- 进度条 ---
        progress = {
          # 何时显示进度条
          # "auto": 智能判断(默认)
          # "always": 始终显示
          # "never": 不显示
          when = "auto";

          # --- 进度条宽度 ---
          # 整数，设置固定宽度(字符数)
          # width = 80;

          # --- 终端集成 ---
          # 向终端仿真器报告进度(如任务栏进度条)
          # term-integration = true;
        };
      };

      # =====================================================================
      # 15. [install] — cargo install 默认设置
      # =====================================================================
      install = {
        # --- 安装根目录 ---
        # cargo install 将可执行文件安装到该目录下的 bin 子目录
        # 默认使用 Cargo home 目录
        # root = "/home/user/.cargo";
      };

      # =====================================================================
      # 16. [paths] — 本地依赖覆盖路径
      # 用于将依赖替换为本地的开发版本
      # 优先级低于 [patch] 和 [source] 替换
      # paths = ["/home/user/dev/my-crate"];
      # =====================================================================

      # =====================================================================
      # 17. [source] — 源码替换
      # 定义注册表源，支持目录源、Git 源、本地注册表源
      # 详见: https://doc.rust-lang.org/cargo/reference/source-replacement.html
      # =====================================================================
      # source = {
      #   # 示例：用本地克隆的 crates.io 索引替换默认源
      #   "crates-io" = {
      #     replace-with = "local-registry";
      #   };
      #   "local-registry" = {
      #     directory = "/path/to/local/registry";
      #   };
      # };

      # =====================================================================
      # 18. [target] — 目标平台特定设置
      # 为特定目标三元组或 cfg() 表达式指定链接器、运行器、rustflags
      # =====================================================================
      target = {
        # --- x86_64 Linux 本机目标 ---
        "x86_64-unknown-linux-gnu" = {
          # --- 链接器 ---
          # 使用 mold 或 lld 链接器可显著加快链接速度
          # linker = "clang";

          # --- 运行器 ---
          # 执行 cargo run/test/bench 时使用的包装器
          # runner = "sudo -E";

          # --- 编译器标志(仅对该目标生效) ---
          # rustflags = "-C target-cpu=native";
        };

        # --- WASM 目标示例 ---
        # "wasm32-unknown-unknown" = {
        #   runner = "wasm-bindgen-test-runner";
        # };

        # --- cfg() 表达式匹配 ---
        # 当 triple 和 cfg 都匹配时，triple 优先
        # "cfg(all(target_arch = \"x86_64\", target_os = \"linux\"))" = {
        #   rustflags = [ "-C" "link-arg=-fuse-ld=mold" ];
        # };
      };

      # =====================================================================
      # 19. [credential-alias] — 凭证提供者别名
      # 定义自定义认证方式的快捷别名
      # 可用于 registry.global-credential-providers 或 registries.<name>.credential-provider
      # =====================================================================
      # credential-alias = {
      #   my-alias = [ "/usr/bin/cargo-credential-example" "--argument" "value" ];
      # };

      # =====================================================================
      # 20. [patch] — 依赖补丁(全局)
      # 与 Cargo.toml 中的 [patch] 格式相同, 但作用于所有构建
      # 多个 patch 按目录层级优先级合并
      # 注意: 会覆盖 Cargo.toml 中的同依赖 patch
      # 建议优先在 Cargo.toml 中配置, 仅在自动生成场景使用此节
      # =====================================================================
      # patch = {
      #   "crates-io" = {
      #     "some-crate" = { git = "https://github.com/user/some-crate"; branch = "fix"; };
      #   };
      # };
    };
  };
}
