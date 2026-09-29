{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # 核心工具链
    rustc
    rustfmt
    clippy

    # rust-src 用于 IDE 自动补全和跳转定义
    (pkgs.runCommand "rust-src" { } ''
      mkdir -p $out/lib/rustlib/src
      ln -s ${pkgs.rustPlatform.rustcSrc} $out/lib/rustlib/src/rust
    '')

    # cargo 扩展
    cargo-edit # cargo add / rm / upgrade
    cargo-watch # 文件变化自动重新编译
    cargo-audit # 依赖安全漏洞扫描
    cargo-nextest # 更快的测试运行器 (下面 nt / nta 两个别名依赖它)
    cargo-flamegraph # 火焰图
    cargo-bloat # 二进制体积构成分析
    cargo-llvm-lines # 单态化产生的 LLVM IR 行数统计
  ];

  # =========================================================================
  # Cargo 全局配置 ($CARGO_HOME/config.toml, 由 Home Manager 生成)
  #
  # 原则: **只写与 cargo 默认值不同的项**。写成默认值的赋值有两个坏处:
  #   1) cargo 升级后默认值变了, 这里会把旧值钉死, 行为悄悄改变;
  #   2) 真正有意的偏离会淹没在大段"抄来的默认值"里, 排障时分不清哪个是刻意选择。
  # 完整选项表(含默认值): https://doc.rust-lang.org/cargo/reference/config.html
  #
  # 下面这些原本显式写成默认值, 2026-09 清理时删除 (要用旧值可从 git 历史取回):
  #   build.jobs="default"、cache.auto-clean-frequency="1 day"、
  #   future-incompat-report.frequency="always"、http.low-speed-limit=10、
  #   http.multiplexing=true、net.git-fetch-with-cli=false、
  #   registry.default="crates-io"、registry.global-credential-providers=["cargo:token"]、
  #   registries.crates-io.protocol="sparse"、term.color="auto"、term.progress.when="auto"、
  #   [profile.dev|release|test|bench] 整节 (opt-level / debug / codegen-units / panic /
  #   lto / overflow-checks / debug-assertions / incremental 逐项等于 cargo 内置默认)
  #
  # 另有三项是**有害**偏离, 一并删除 (默认都是 auto-detect, 写死会破坏自动判断):
  #   term.hyperlinks = true、term.unicode = true —— 非 TTY / 非 UTF-8 场景也照样
  #   输出超链接与 Unicode 字符, 污染重定向的日志;
  #   cargo-new.vcs = "git" —— 覆盖了"已在 VCS 内则默认 none"的自动判断,
  #   在仓库内跑 `cargo new` 会多建一个嵌套 git 仓库
  # =========================================================================
  programs.cargo = {
    # 启用后才会把下面的 settings 写进 $CARGO_HOME/config.toml
    enable = true;
    package = pkgs.cargo;
    # cargoHome 保持默认 (~/.cargo), 不再额外导出 CARGO_HOME

    settings = {
      # --- 命令别名 ---
      # cargo 自带 b / c / d / t / r / rm, 这里只列自定义的
      alias = {
        rr = "run --release"; # release 模式运行
        ca = "check --all-targets"; # 检查所有目标 (lib/bin/test/example)
        cr = "check --release";
        re = [ "run" "--example" ]; # cargo re <名称> 运行某个 example
        up = "update"; # cargo up <crate> 只更新单个依赖
        nt = "nextest run"; # 依赖上面的 cargo-nextest
        nta = "nextest run --all-targets";
      };

      # --- 网络 ---
      # 国内到 crates.io 的链路容易慢/断, 放宽超时与重试 (cargo 默认 30 秒 / 3 次)
      http.timeout = 60;
      net.retry = 5;

      # --- 依赖解析 ---
      # 明示 allow: resolver v3 (edition 2024 的默认) 会把这一项的默认从 allow 改成
      # fallback; 明示后不受影响 —— 本机 rustc 来自 nixpkgs 且版本足够新, 不需要
      # resolver 因为依赖的 rust-version 字段而退到更旧的版本
      resolver.incompatible-rust-versions = "allow";

      # --- 需要时再打开的覆盖 (示例值; 默认值见官方文档) ---
      # build.rustc-wrapper = "${pkgs.sccache}/bin/sccache"; # 编译缓存
      # profile.release.lto = "thin"; # 发布产物做 thin LTO
      # profile.release.strip = "symbols"; # 发布产物剥掉符号
      # build.rustflags = [ "-C" "target-cpu=native" ];
      # http.proxy = "http://127.0.0.1:20172"; # 需要显式代理时 (本机透明代理通常不必)
    };
  };
}
