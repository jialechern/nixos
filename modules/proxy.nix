{
  config,
  lib,
  ...
}:

let
  cfg = config.machine.proxy;

  # 大小写两套都给: libcurl 只读小写, Chromium/CEF 与部分 Java/Go 生态读大写
  proxyEnv = {
    http_proxy = cfg.httpUrl;
    https_proxy = cfg.httpUrl;
    ftp_proxy = cfg.httpUrl;
    HTTP_PROXY = cfg.httpUrl;
    HTTPS_PROXY = cfg.httpUrl;
    FTP_PROXY = cfg.httpUrl;
    no_proxy = cfg.noProxyString;
    NO_PROXY = cfg.noProxyString;
  };
in
{
  # 本机出网配置的单一事实源: 代理端口/地址/no_proxy 与包管理器镜像地址
  # 只在这里出现一次, 其它模块一律引用
  # (参考 nixpkgs 自己的 networking.proxy.default + 派生字段 的范式, 见
  # nixos/modules/config/networking.nix:77-157)。代理软件本身的装配仍在
  # modules/service.nix 里, 本文件对"用 v2raya 还是 mihomo"无感知。
  options.machine.proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        总开关: 关掉后 env 退化为空, 所有消费方 (steam、nix-daemon) 随之不再
        注入代理, 不必逐个注释。
      '';
    };

    clientHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        本机应用连接代理用的地址。与"是否对局域网开放"无关: 客户端始终连回环,
        即使代理服务本身监听 0.0.0.0。
      '';
    };

    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 20172;
      description = ''
        HTTP 代理端口, 必须与 v2raya 设置里的 HTTP 端口一致。v2raya 的端口只能在
        它的 GUI 里改, 所以改这里之后必须同步 GUI, 否则所有消费方都会指向死端口。
      '';
    };

    noProxy = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "localhost" "127.0.0.1" "::1" ];
      description = ''
        不走代理的域名/地址 (no_proxy)。想让 Steam 下载这类大流量直连时,
        把 steamcontent.com 等域名追加进来。
      '';
    };

    lanListen = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        是否同时允许局域网设备经本机代理上网 (决定防火墙是否放行 httpPort)。
        打开时还需在 v2raya 的 GUI 里把监听地址改为 0.0.0.0。
      '';
    };

    # --- 派生量: 只读, 消费方不得自己拼 host/port ---
    httpUrl = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "http://${cfg.clientHost}:${toString cfg.httpPort}";
      defaultText = lib.literalExpression ''"http://''${clientHost}:''${httpPort}"'';
      description = "完整的代理 URL。";
    };

    noProxyString = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = lib.concatStringsSep "," cfg.noProxy;
      description = "no_proxy 环境变量的字符串形式 (逗号分隔, 不带空格)。";
    };

    # --- 包管理器镜像: 刻意直连国内镜像, 不经过 httpUrl 的代理 ---
    # 与上面的端口/no_proxy 同一思路: go / cargo / npm 的镜像地址只在这里声明,
    # 换镜像只改一处。与 enable 无关: 关掉代理后镜像依然生效。
    # 只有 go 经 toolchainEnv 以环境变量形式由 nix-daemon 下发到沙箱; cargo 与 npm
    # 是配置文件, 由 Home Manager 侧经 osConfig 读取。
    goProxy = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "https://goproxy.cn,direct";
      description = ''
        GOPROXY 的值。proxy.golang.org 直连必然 TLS handshake timeout, 经本机代理
        又慢又不稳, 所以走 goproxy.cn, 失败再回源 (direct)。镜像内容的完整性由
        go.sum 与固定输出派生的 outputHash 双重保证。
      '';
    };

    cratesIoIndex = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";
      description = ''
        cargo 用的 crates.io 稀疏索引。USTC 镜像的 config.json 把 dl 也指向自己的
        镜像, 所以 .crate 包本体同样不直连 static.crates.io。
        消费方: home/dev/rust.nix 的 source replacement (这是配置项而非环境变量,
        无法经 toolchainEnv 下发)。
      '';
    };

    npmRegistry = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "https://registry.npmmirror.com";
      description = ''
        阿里云 npmmirror (原淘宝 npm, 官方维护, 约 10 分钟同步一次官方源) 的地址。
        消费方: home/dev/nodejs.nix 的 ~/.npmrc `registry=` 与 home/shell/pi.nix 的
        `npmCommand --registry=`, 均经 `osConfig` 读取。
        与 cratesIoIndex 同性质: 配置项而非环境变量, 不进 toolchainEnv ——
        nixpkgs 的 importNpmLock 用 fetchurl 逐个取包, 其 impureEnvVars 白名单里
        只有 *_proxy, 沙箱里读不到 registry 环境变量 (只有 fetch-pnpm-deps 认
        NIX_NPM_REGISTRY)。
      '';
    };

    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = if cfg.enable then proxyEnv else { };
      defaultText = lib.literalMD "由 `enable` / `httpUrl` / `noProxyString` 派生";
      description = ''
        可直接赋给 `systemd.services.<name>.environment` 或
        `pkgs.steam.override { extraEnv = ...; }` 的环境变量集
        (http/https/ftp 的大小写两套 + no_proxy)。
      '';
    };

    toolchainEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = { GOPROXY = cfg.goProxy; };
      defaultText = lib.literalMD "由 `goProxy` 派生";
      description = ''
        工具链镜像的环境变量形式, 可直接赋给 `systemd.services.<name>.environment`
        (如 nix-daemon)。与 `env` 的键集不相交, 消费方可 `unionOfDisjoint` 合并。
        注意: 只对经 nix-daemon 的构建生效; root 重建需带 `--option store daemon`。
      '';
    };
  };
}
