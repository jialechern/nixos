# buildFHSEnv 声明式 FHS 环境模板 (nix-tool references)

> 何时读: SKILL.md §5.1 — steam-run/appimage-run 等临时 FHS 方案仍缺库, 用户确认需要长期使用, 需转声明式时。
> 目标读者是 agent: 拿到此模板即可在用户配置中落地, 无需其它本机知识。

## 1. 适用场景

- 运行未打包的预编译二进制 / AppImage / 第三方安装器
- 症状: `no such file or directory`、缺 `/lib/...`/`/usr/lib/...` 下的共享库、直接段错误、`/bin/bash: bad interpreter` 类错误

## 2. 核心方法 (两条规则)

| 规则 | 含义 |
| --- | --- |
| `targetPkgs` | 环境内要用的**命令/可执行程序** (会放进 `/usr/bin` 等 FHS 路径) |
| `multiPkgs` | 环境内可见的**共享库** (只装库不装命令); 缺库报错时把库名加到这里 |

其它字段: `runScript` 进入环境后执行的程序 (默认 bash); `profile` 进入时 source 的片段 (可放环境标记变量); `extraOutputsToInstall` 顺带链接 dev output (头文件等, 需编译时用)。

## 3. 最小模板 (可直接复制到配置)

放在 home-manager 的 `home.packages` (或系统 `environment.systemPackages`) 中, 生成的可执行命令名 = `pname`:

```nix
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.buildFHSEnv {
      pname = "fhs";          # 生成的 wrapper 命令名 (终端输入 fhs 进入环境)
      version = "0.1";
      runScript = "bash";     # 进入环境后启动 bash
      profile = "export FHS=1";   # 可选: 供脚本判断"当前是否在 FHS 环境内"

      # 环境内可执行程序 (缺命令 → 加这里)
      targetPkgs = pkgs: with pkgs; [
        pkg-config
        ncurses
      ];

      # 环境内可见的共享库 (缺库 → 加这里)
      multiPkgs = pkgs: with pkgs; [
        zlib
        glib
        libGL
        openssl
        fontconfig
        freetype
        # ...按需追加报错缺失的库
      ];
    })
  ];
}
```

## 4. 生产级 multiPkgs 清单来源

逐库手填易漏。AppImage 官方有 excludelist 覆盖绝大多数 GUI 程序的运行库需求, nixpkgs 已将其固化, 可直接对照同步:

- nixpkgs 源码: `pkgs/build-support/appimage/default.nix` 中 `defaultFhsEnvArgs.multiPkgs`
- steam-run 的 FHS 环境 (`pkgs/development/tools/steam-run` 或由 `steam-fhsenv` 派生) 也是现成参考

若目标程序是 AppImage/闭源 GUI, 建议直接以上述清单为基底, 再按报错追加缺失库; 若是命令行工具, 从最小集开始按报错迭代即可。

## 5. 落地方向

- 完整声明式示例形态即上文模板; 具体放在用户配置仓库的哪个模块由用户决定。
- 修改后需用户执行系统重建 (`sudo nixos-rebuild switch`) 生效 — 这是持久化路径, 不是 nix-tool 临时流程的一部分 (见 SKILL.md §6 第 5 步)。
