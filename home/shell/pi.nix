{
  config,
  pkgs,
  inputs,
  ...
}:

let
  # ---------------------------------------------------------------------------
  # pi 配置目录
  # pi 配置根目录: 与上游 CLI 默认值 ~/.pi/agent 一致
  # 显式写出 (而非依赖模块默认值), 防止上游将来变更默认路径影响本配置
  # ---------------------------------------------------------------------------
  piConfigDir = "${config.home.homeDirectory}/.pi/agent";

  # ---------------------------------------------------------------------------
  # git push 红线: 只作用于 pi 进程树 (用户自己终端的 git 完全不受影响)
  #
  # 做法: pi 包装脚本注入 GIT_CONFIG_COUNT/KEY_0/VALUE_0, 把 pi 环境内的
  # core.hooksPath 指向下面这份 store hooks; 于是 pi 内任何 git 命令 (bash 工具 /
  # 子代理 / 扩展子进程) 都走这里的 pre-push, 而用户终端的 git 不读这些变量。
  #   * pre-push: 直接 exit 1, 拦截 pi 会话内发起的 git push
  #   * 其余 hook: 软链到转发脚本, 仍执行仓库自身生效的 hook —— GIT_CONFIG_* 是
  #     命令行级配置, 会盖掉仓库本地的 core.hooksPath (husky 等), 不转发的话
  #     pi 内的 git commit 会静默跳过仓库 hook
  # 已知绕过面 (hook 层覆盖不到, 只靠 AGENTS.md 红线约束, 不在这里加文本匹配):
  #   --no-verify、显式 -c core.hooksPath=…、清空 GIT_CONFIG_*、send-pack 等
  #   不经 push 路径的推送 (实测不触发 pre-push)、非 git 工具直连远端、sudo 清环境后执行。
  # ---------------------------------------------------------------------------
  piGitHookChain = pkgs.writeShellScript "pi-git-hook-chain" ''
    # 转发到仓库自身生效的 hook: 先看仓库/全局配置里的 core.hooksPath, 没有则用 $GIT_DIR/hooks
    hook=''${0##*/}
    repo_hooks=$(env -u GIT_CONFIG_COUNT -u GIT_CONFIG_KEY_0 -u GIT_CONFIG_VALUE_0 \
      git config --get core.hooksPath 2>/dev/null || true)
    if [ -n "$repo_hooks" ]; then
      target="$repo_hooks/$hook"
    else
      common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) \
        || common=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
      target="$common/hooks/$hook"
    fi
    [ -x "$target" ] || exit 0
    exec "$target" "$@"
  '';

  # 需要链式转发的 hook 名 (githooks(5)); pre-push 不在此列, 它是拦截本体。
  # 服务端名字也得给: 本地路径作远端时 receive-pack 会继承 pi 环境, 不转发它们会消失
  piGitHookNames = [
    "applypatch-msg"
    "pre-applypatch"
    "post-applypatch"
    "pre-commit"
    "pre-merge-commit"
    "prepare-commit-msg"
    "commit-msg"
    "post-commit"
    "pre-rebase"
    "post-checkout"
    "post-merge"
    "pre-auto-gc"
    "post-rewrite"
    "sendemail-validate"
    "fsmonitor-watchman"
    "p4-changelist"
    "p4-prepare-changelist"
    "p4-post-changelist"
    "p4-pre-submit"
    "post-index-change"
    "reference-transaction"
    "pre-receive"
    "update"
    "proc-receive"
    "post-receive"
    "post-update"
    "push-to-checkout"
  ];

  piGitHookDir = pkgs.runCommandLocal "pi-git-hooks" { } ''
    mkdir -p $out
    ln -s ${pkgs.writeShellScript "pi-pre-push-deny" ''
      echo "本机红线: pi 会话内禁止 git push。需要推送时请让用户在自己的终端手动执行, 不要尝试绕过。" >&2
      exit 1
    ''} $out/pre-push
    for hook in ${pkgs.lib.concatStringsSep " " piGitHookNames}; do
      ln -s ${piGitHookChain} $out/$hook
    done
  '';

  # ---------------------------------------------------------------------------
  # pi 项目级扩展集合 (extension groups)
  #
  # 这些包不进全局 settings.packages, 因此未装配它们的项目是零启动成本;
  # 包列表内联在下方 home.file 的 ~/.pi/agent/extension-groups.json, 定义了
  # init / coding 两个组, 由用户级扩展 extensions-manager.ts (同样经
  # home.file 部署) 的 /exts 命令在 pi 会话内装配到当前项目的 .pi/settings.json:
  #   装配基础集合  /exts add-group init     (幂等, 已装的跳过)
  #   装配编码集合  /exts add-group coding
  #   卸载全部      /exts clean             (带确认; -y 跳过)
  #   查看清单      /exts list              (含组标注; 组名 Tab 补全)
  # 装配后扩展自动 reload 生效, 无需重启 pi。
  # 注: 写操作要求项目已被信任 (会话内用 /trust 授予), 未信任时 /exts 会
  # 弹确认, 或加 -y 直接写入 (不保存信任决定); list 始终可用。
  # ---------------------------------------------------------------------------

in
{
  programs.pi-coding-agent = {
    # 必须启用才会安装软件包并生成配置
    enable = true;

    # 包来源: 上游官方 flake (flake.nix 的 pi input, 跟踪 stable 分支 ⇒ 最新正式版),
    # 不再是 nixpkgs 的 pi-coding-agent。上游包 pname = "pi"、bin/pi 与 meta.mainProgram
    # 不变, 所以下面的 wrapProgram 与 extraPackages 全部无需改动。
    #
    # 包装注入两样东西:
    #   (1) sops-nix 生成的密钥到 pi 进程环境: 直接读密钥文件 (由 sops.nix 的 secrets
    #       声明生成, 权限 0400/0600), 不再额外落一份明文 env 文件 —— 旧的
    #       ~/.config/pi/secrets.env 可以手动删掉;
    #   (2) GIT_CONFIG_* 把 pi 环境的 core.hooksPath 指向 git push 拦截 hooks
    #       (见本文件 let 块的 piGitHookDir 注释), 只约束 pi 进程树。
    #
    # sops.nix 是 pathExists 可选开关 (home.nix:45-53), 它缺席时 config.sops 这棵
    # 选项树整个不存在, 所以密钥注入必须在求值期分支: 用 config ? sops 判断
    # "sops-nix 的 HM 模块是否被导入", 与 home.nix 的开关同构。否则按 README 的
    # 无代理首装流程移走 sops.nix 后, 这里会抛 "attribute 'sops' missing", 失败面是
    # 全部 HM 配置 (2026-10-04 复评 P1-1)。没有 sops 时包装照做 (git hooks 拦截不依赖
    # sops), 只是拿不到这几个 API key (扩展按缺 key 降级), 运行期的密钥缺失守卫
    # (下方 load_secret) 仍然生效。
    #
    # 有意取舍: 密钥变量会随 pi 进程进入它派生的所有子进程环境 (包括 bash 工具),
    # 因为 pi 的联网搜索/文档查询/GitHub 能力都从进程环境里读 key。
    # 若以后要收紧, 可改成只给需要的扩展单独传 env, 而不是在启动时全量导出。
    package =
      let
        secretsRun = pkgs.lib.optionalString (config ? sops) ''
          --run '
            # 只在密钥文件存在且非空时导出: 直接 export 空串会覆盖用户已有环境变量,
            # 并让 pi 的扩展抛 environment-empty 而不是回退 (2026-09-29 复评 NEW-10);
            # 注意 wrapper 由 makeWrapper 以 bash -e 运行, 守卫必须 errexit 安全
            # (不能用 "&&" 结尾 —— 缺失文件时会因返回非零而中止整个 pi 启动)
            load_secret() { local k; k="$(cat "$2" 2>/dev/null || true)"; [ -z "$k" ] || export "$1=$k"; }
            load_secret DEEPSEEK_API_KEY "${config.sops.secrets.deepseek_api_key.path}"
            load_secret TAVILY_API_KEY "${config.sops.secrets.tavily.path}"
            load_secret FIRECRAWL_API_KEY "${config.sops.secrets.firecrawl.path}"
            load_secret CONTEXT7_API_KEY "${config.sops.secrets.context7.path}"
            load_secret GH_TOKEN "${config.sops.secrets.github_pull_only_token.path}"
          '
        '';
      in
      pkgs.symlinkJoin {
        name = "pi-coding-agent-wrapped";
        paths = [ inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/pi \
            --set GIT_CONFIG_COUNT 1 \
            --set GIT_CONFIG_KEY_0 core.hooksPath \
            --set GIT_CONFIG_VALUE_0 ${piGitHookDir} \
            ${secretsRun}
        '';
      };

    # 扩展包运行时依赖: pi install npm:... 安装扩展 (如 @termdraw/pi) 需要 npm 与 bun
    # gh: pi-web-access 的 GitHub 能力 (PR/Issue 富字段视图、私有库、超大仓库 API 路径)
    #     注: gh 不读 .netrc, 认证靠 sops.nix 注入 pi 进程的 GH_TOKEN
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
      pkgs.gh
    ];

    # 配置目录 (见文件头"一")
    configDir = piConfigDir;

    # -------------------------------------------------------------------------
    # pi 快捷键 (keybindings.json)
    #
    # 原则: 只写"pi 默认没给, 或默认键要让给别人"的项, 其余全部吃默认值。
    # 一个键要按得动, 必须穿过四层: niri(Super+*) → kitty → pi 动作层 → 扩展。
    # kitty 把 ctrl+shift+* 当自留地 (它自带 86 条默认 map, 见 home/desktop/kitty.nix),
    # 让路手段是 `map <key> no_op`。所以下面一律选"两层都空闲"的键:
    # 不用 ctrl+shift+* (除 ctrl+shift+\), 不用 alt+f/h/j/k/l/n/p/r/w/x/1-9 (kitty 已占),
    # 也不用 alt+s (kitty 的 chord 前缀)。
    # 插件自己的键不在这里: rpiv-todo 的 collapseKey、web-search.json 的 shortcuts。
    # -------------------------------------------------------------------------
    keybindings = {
      # --- 列表导航 (vim 风格) ---
      # 默认只有 ↑↓; 加上 ctrl+p / ctrl+n 后, 模型选择器 / 会话恢复 / 问答对话框
      # 等所有选择列表统一为 vim 键位。代价是这两个键本是 app.model.cycleForward
      # (ctrl+p) 与 app.session.toggleNamedFilter (ctrl+n) 的默认值, 故下面分别
      # 改到 ctrl+\ 与 ctrl+,; 又因 /resume 里 app.session.togglePath /
      # toggleNamedFilter 的匹配优先于 tui.select.*, 那两个专用键也必须一起让位。
      "tui.select.up" = [
        "up"
        "ctrl+p"
      ]; # 上移
      "tui.select.down" = [
        "down"
        "ctrl+n"
      ]; # 下移

      # --- 会话选择器 (/resume) 专用键 ---
      # 默认 ctrl+p (切换路径显示) / ctrl+n (仅命名会话过滤), 与上面的列表导航撞键
      # 且匹配优先级更高; 改到 ctrl+. / ctrl+, (pi 与 kitty 两层都空闲)
      "app.session.togglePath" = "ctrl+."; # 切换路径显示
      "app.session.toggleNamedFilter" = "ctrl+,"; # 仅显示命名会话

      # --- 模型循环 ---
      # 默认 ctrl+p / shift+ctrl+p: 前者已让给列表导航, 后者在 kitty 层是 chord 前缀
      # (kitty_mod+p>shift+f 等 9 条), 故改用两层都空闲的 ctrl+\ / ctrl+shift+\
      "app.model.cycleForward" = "ctrl+\\"; # 循环到下一个模型
      "app.model.cycleBackward" = "ctrl+shift+\\"; # 循环到上一个模型

      # --- 思考块折叠 ---
      # 默认 ctrl+t, 改用 ctrl+f (两层都空闲)。注意 ctrl+f 同键还有编辑器动作
      # tui.editor.cursorRight, 二者谁优先上游没有明文规定 (docs/keybindings.md 只写了
      # fullscreen 组优先于 editor); 若实测是"光标右移"胜出, 想折叠思考块就换回
      # ctrl+t 或其它空闲键 —— 两种情况都不丢功能 (方向键 right 仍在)。
      "app.thinking.toggle" = "ctrl+f"; # 折叠/展开思考块

      # --- 显式禁用 ---
      # 全屏模式下的转录搜索 (本机 tuiMode = "regular", 该动作惰性)。
      # 默认 ctrl+shift+f 与 rpiv-todo 的面板折叠键同键, 而 tui.altScreen.search 不在
      # pi 的"扩展不许抢"保留清单里 (src 的 RESERVED_KEYBINDINGS_FOR_EXTENSION_CONFLICTS,
      # 共 18 条) ⇒ 会被扩展抢走并每次启动告警; 且该键在 kitty 层被 toggle_fullscreen
      # 拦截, 本来就按不到。置空 = 不绑任何键, 无冲突无告警。
      "tui.altScreen.search" = [ ];
    };

    # -------------------------------------------------------------------------
    # 自定义模型 (models.json)
    # providers 目前留空: 内置目录已覆盖当前所用模型 (deepseek-flash 的 contextWindow /
    # maxTokens / thinkingLevelMap / cost 都在内置条目里, 认证由 /login deepseek 写入
    # auth.json)。只有 pi.dev 远程目录尚未收录某个新模型时, 才在这里加 provider 条目
    # (baseUrl / api / models[...]), 字段写法参考内置条目。
    # -------------------------------------------------------------------------
    models = {
      providers = { };
    };

    # -------------------------------------------------------------------------
    # pi 全局设置 (settings.json, 含全局扩展包)
    # -------------------------------------------------------------------------
    settings = {
      # --- 模型与思考 ---
      defaultProvider = "deepseek"; # 默认提供商
      defaultModel = "deepseek-flash"; # 默认模型
      defaultThinkingLevel = "high"; # 默认思考等级

      # --- 模型作用域 (0.99.0 起) ---
      # 限定"启动选择"与 ctrl+\ 循环的模型集合 (= /scoped-models 显示的那份)。
      # 匹配规则: pi 内部对 "provider/modelId" 与裸模型 id 各做一次大小写不敏感的
      # minimatch (dist/core/model-resolver.js), 所以用 provider 前缀限定即可。
      # 需要临时用别的模型时改这里再 rebuild, 或用 /scoped-models 做会话级调整。
      enabledModels = [
        "deepseek/*"
        "zai-coding-cn/*"
      ];

      # 每个模型的起始思考等级 (0.99.0 起; 键为 provider/modelId, 优先于 defaultThinkingLevel)。
      # 两家模型的可用档位一致: low / high / max (内置目录里 minimal/medium 为 null),
      # 显式写出后, 切换模型时不会被全局默认值带偏。
      modelThinkingLevels = {
        "deepseek/deepseek-flash" = "high";
        "zai-coding-cn/glm-5.3-flash" = "high";
      };

      # 缓存未命中 / 成功预热 / 压缩 / 供应商恢复等提示 (默认关闭)
      # deepseek 的 cacheRead 单价 $0.006/M 而输入 $0.3/M (约 1/50), 值得观察命中情况
      showCacheMissNotices = true;

      # --- UI 与显示 ---
      # system (0.99.0 起的内置默认): 运行时向终端取前景/背景/ANSI 调色板动态生成配色,
      # 按 WCAG 4.5:1 对比度自动调明度。kitty 本身就是 Catppuccin Mocha, 让 pi 直接跟随
      # 终端配色, 不再维护自定义主题文件 (原 catppuccin-mocha-mauve.json 已删除)。
      # 注: system 是保留名; 若要精确控制各角色配色 (如 mauve 强调) 可再放回自定义主题
      theme = "system";
      # 显式钉住 regular: pi 0.99.2 默认即 regular (写出为幂等), 但 1.0.0 起默认改为
      # fullscreen —— 写出该键保证将来 flake update 升级后 TUI 仍用终端原生滚动回滚,
      # 行为不变。要体验 1.0.0 全屏模式时删掉本行或改为 "fullscreen" 即可
      tuiMode = "regular";

      # 全屏模式 (tuiMode = "fullscreen") 下滚轮每格滚动行数: pi 0.99.0 起的官方
      # 设置 (取值 1-100 或 "auto")。注意: 仅 fullscreen 模式生效 —— 当前
      # tuiMode = "regular" 时它是惰性的, 保留以便以后试验全屏。
      fullscreenWheelScrollLines = 4;

      # 启动横幅 (1.0.0 起): "header" 只保留 logo/版本/按键提示,
      # 隐藏模型范围行与已加载资源清单 (清单随项目装配的扩展变化, 通常占好几行)
      quietStartup = "header";

      # 升级后显示精简 changelog: 版本由 flake update 驱动, 升级后一眼看到改了什么
      collapseChangelog = true;

      # kitty 标签页显示进度 (OSC 9;4)
      terminal.showTerminalProgress = true;

      # --- 自动压缩 (官方文档示例推荐值) ---
      compaction = {
        enabled = true;
        reserveTokens = 16384; # 为 LLM 回复预留的 token
        keepRecentTokens = 20000; # 保留不摘要的最近 token
      };

      # --- 重试 (官方文档示例推荐值) ---
      retry = {
        enabled = true;
        maxRetries = 3;
      };

      # --- 网络代理 (可选) ---
      # 国内访问海外 API (如 OpenCode Zen/Go ...) 时启用, 走本机代理 127.0.0.1:20172
      # pi 会将其应用为 HTTP_PROXY / HTTPS_PROXY。只能在 agent 目录级 settings 配置
      # (pi 文档 docs/settings.md: "Can only be set in agent-directory settings"), 项目级不可覆盖
      # httpProxy = "http://127.0.0.1:20172";

      # --- 内置扩展开关 (0.99.0 起) ---
      # 内置扩展名为 builtin:mcp / builtin:llama.cpp / builtin:codemode / builtin:tool-search,
      # 默认全部加载; 本机不使用本地 GGUF 模型 (/llama), 故禁用 llama.cpp 那一项。
      # "-" 前缀表示禁用, "+" 表示显式启用; 项目级 settings 可用 + 覆盖本项。
      extensions = [ "-builtin:llama.cpp" ];

      # --- 默认工具集 ---
      # builtin:codemode 注册的 codemode 工具默认 inactive (内置扩展的激活只有两种途径:
      # 本项显式启用, 或 MCP 服务器以 codemode 暴露时自动激活), 这里显式打开试水。
      # "+" 前缀表示在继承的默认选择 (read/bash/edit/write) 上追加, 不替换它们。
      # 代价: 每次请求的固定前缀 +约 500 token (实测 499, deepseek-flash 计数;
      # 构成 = codemode 自身声明 ~1520 字符 + 每个已声明工具描述尾追加一行 ~52 字符
      # + 系统提示词 tools/rules 两段 ~190 字符)。位于稳定前缀内, 缓存命中后开销可忽略。
      # 收益: 脚本内并行调多个工具、先把大输出过滤再回传; 接 MCP 后其工具不占声明位。
      # 试用不满意就把本项删掉 (或写成 [ "-codemode" ]) 后 rebuild。
      # 参考 pi 1.0.2 文档 docs/codemode.md 与 docs/cli.md#enable-codemode
      defaultTools = [ "+codemode" ];

      # --- npm 镜像 ---
      # pi 查找/安装 npm 扩展时使用 —— 含 /exts add-group 经 pi install 装到项目的
      # 扩展 (源见下方 extension-groups.json); 写进配置就不依赖 ~/.npmrc
      npmCommand = [
        "npm"
        "--registry=https://registry.npmmirror.com"
      ];
    };

    # -------------------------------------------------------------------------
    # AGENTS.md: 全局上下文 (作用于所有项目)
    # 文档: https://pi.dev/docs/latest/quickstart (Give pi project instructions)
    # 修改后需 /reload 或重启生效
    # -------------------------------------------------------------------------
    context = ./pi/AGENTS.md;
  };

  # ---------------------------------------------------------------------------
  # home.file: 主题 / 提示词模板 / 各扩展配置
  # 注: 凡是用 builtins.toJSON 生成的 json, 都是"声明式只读"的 —— 指向 nix store
  # 的符号链接, 在 pi 内改这些配置不会落盘, 改配置请改本文件后 rebuild。
  # ---------------------------------------------------------------------------
  home.file = {
    # pi-web-access 搜索配置: 复用 sops 注入的 TAVILY_API_KEY / FIRECRAWL_API_KEY
    # $VAR 在请求时解析 (环境变量由 pi 包装脚本启动时从 sops 密钥文件读出并导出)
    ".pi/agent/web-search.json".text = builtins.toJSON {
      # --- 搜索凭据 ---
      # 显式声明凭据来源便于自文档化; 环境变量优先级高于此处的字面值
      tavilyApiKey = "$TAVILY_API_KEY";
      firecrawlApiKey = "$FIRECRAWL_API_KEY";

      # --- 搜索路由 ---
      # 不设 provider (其优先级高于 searchRouting, 会覆盖路由):
      # 先用 Tavily, 失败退 Firecrawl, 再失败退 Exa (无 key 时走托管 MCP,
      # 免凭据兜底; 实测 mcp.exa.ai 可直连)。
      # fallbackOn 决定哪类错误继续尝试下一个 provider; 它不含凭据类错误,
      # 所以 key 配错不会继续回退, 而是就地返回诊断
      searchRouting = {
        providers = [
          "tavily"
          "firecrawl"
          "exa"
        ];
        fallbackOn = [
          "transient"
          "quota"
          "network"
          "invalid-response"
        ];
      };

      # --- 交互与快捷键 ---
      # none: web_search 直接返回原始结果, 不弹浏览器策展窗口
      workflow = "none";
      # 两个默认键都被 kitty 拦截 (2026-10-04 核实, 规则见 home/desktop/kitty.nix):
      #   curate   ctrl+shift+s → kitty 的 search_scrollback
      #   activity ctrl+shift+w → kitty 的 close_window (按一下直接关窗口)
      # 故一并改到 kitty 层空闲的 alt 键。注: 扩展注册的是字面量键, 不能用
      # keybindings.json 改, 只能在这里改 (web-search.json 也是 builtins.toJSON 生成)。
      shortcuts = {
        curate = "alt+u";
        activity = "alt+a";
      };

      # --- 工具 / 命令 / 图片开关 (显式写出, 便于日后核对) ---
      tools = {
        webSearch = {
          enabled = true;
        };
        sourceCheck = {
          enabled = true;
        };
        fetchContent = {
          enabled = true;
        };
        getSearchContent = {
          enabled = true;
        };
      };
      commands = {
        websearch = {
          enabled = true;
        };
        curator = {
          enabled = true;
        };
        search = {
          enabled = true;
        };
        "google-account" = {
          enabled = true;
        };
      };
      image = {
        enabled = true;
      };

      # --- 内容提取 ---
      # fetch_content 内联切片, 同时是 get_search_content 的默认/最大切片
      maxInlineContentChars = 30000;
      fetch = {
        timeout = 30;
      };
      # 无 Datalab / Gemini key, auto 会落到本地 unpdf (纯文本, 离线免费)
      pdf = {
        provider = "auto";
        maxSizeMB = 20;
        maxPages = 100;
      };

      # --- GitHub ---
      # 公共库直接 clone 到本地; 超过 350MB 走 API 轻量视图
      # gh CLI 由本文件 programs.pi-coding-agent.extraPackages 提供,
      # 认证靠 sops.nix 注入的 GH_TOKEN;
      # 未认证或 gh 失败时 PR/Issue 降级到未认证 REST (仅公共库, 限流 60/h, 无 checks)
      githubClone = {
        enabled = true;
        maxRepoSizeMB = 350;
        cloneTimeoutSeconds = 30;
      };
      githubPrIssue = {
        enabled = true;
      };

      # --- 视频 ---
      # 无 GEMINI_API_KEY / Gemini Web cookie / Perplexity key 时, YouTube 与本地视频
      # 分析都会失败, 但 enabled = true 会返回明确可操作的报错
      # ("Sign into Google ... or set GEMINI_API_KEY"), 优于静默退化成普通网页抓取。
      # 注意: 本地视频抽帧受 video.enabled 门控; YouTube 抽帧只受 image.enabled 门控,
      # 用 yt-dlp + ffmpeg 本地完成, 不需要 API key。
      youtube = {
        enabled = true;
      };
      video = {
        enabled = true;
      };

      # --- SSRF ---
      # 保持默认为空: 本机 v2raya 未使用 TUN/fake-IP (公共域名解析到真实 IP),
      # 无需豁免 198.18.0.0/15 等保留段; 保留完整 SSRF 防护
    };

    # rpiv-todo 配置: 折叠面板的快捷键
    # 插件默认 ctrl+shift+t, 本机为 ctrl+shift+f —— 但两者都被 kitty 拦截
    # (ctrl+shift+t = new_tab, ctrl+shift+f = 本仓库绑定的 toggle_fullscreen),
    # pi 收不到, 折叠功能目前实际不可用; 换成 alt+t / alt+o (kitty 层空闲) 即可恢复。
    # pi 侧已把同键的 tui.altScreen.search 置空, 所以这里不产生扩展抢键告警。
    # 文档: https://github.com/juicesharp/rpiv-mono/tree/main/packages/rpiv-todo
    ".config/rpiv-todo/config.json".text = builtins.toJSON {
      collapseKey = "ctrl+shift+f";
    };

    # pi 用户级扩展 extensions-manager.ts: 注册 /exts 命令, 在会话内对当前
    # 项目装配/卸载/清点 extension-groups.json 里定义的插件组 (见本文件头部注释)。
    # 部署为只读软链即可: pi 经 jiti 直接运行 TS 源码, 无需编译
    # (文档: pi docs/extensions.md 的 "Add it to Pi")
    ".pi/agent/extensions/extensions-manager.ts".source = ./pi/extensions-manager.ts;

    # 插件组定义 (声明式只读: 改组请改本文件后 rebuild); 某个项目想用不同的
    # 组内容时, 可在该项目 .pi/extension-groups.json 定义同名组整体覆盖。
    ".pi/agent/extension-groups.json".text = builtins.toJSON {
      # 基础集合: 通用能力, 任何项目都可能想要
      init = {
        description = "基础集合: 通用能力, 任何项目都可能想要 (待办 / 子代理 / 网页访问)";
        packages = [
          # 待办清单 (MIT, juicesharp): todo 工具 + /todos 命令 + 编辑器上方实时面板
          # 面板折叠键在 ~/.config/rpiv-todo/config.json 绑定为 ctrl+shift+f
          # 注意 (2026-10-04 核实): 该键被 kitty 的 toggle_fullscreen 拦截
          # (home/desktop/kitty.nix 的 "ctrl+shift+f"), pi 收不到 —— 折叠功能实际不可用;
          # 换到 alt+t 之类 kitty 层空闲的键即可恢复。pi 侧已把同键的
          # tui.altScreen.search 置空, 因此这里不产生扩展抢键告警。
          "npm:@juicesharp/rpiv-todo"
          # 子代理: 把任务委托给专注的子会话
          "npm:pi-subagents"
          # 网页访问: 搜索 / 抓取 / GitHub 克隆 / PDF / 视频理解
          # 配置见上方 home.file 的 ~/.pi/agent/web-search.json
          "npm:pi-web-access"
        ];
      };
      # 编码集合: 与基础集合正交, 只含编码相关。
      # add-group 是幂等追加, 各组叠加即得并集: 日常项目只装 init 保持轻量,
      # 编码项目再叠加 coding, 主动用启动耗时换功能。
      # 需要继续细化时可再加一组 (如 audit → 审计集合)。
      coding = {
        description = "编码集合: 实时代码反馈 LSP 诊断 / linter / autofix (与基础正交)";
        packages = [
          # 实时代码反馈 (LSP 诊断 / linter / autofix)
          "npm:pi-lens"
          # 简单代码审查
          "npm:pi-simplify"
        ];
      };
    };
  };

  # ---------------------------------------------------------------------------
  # shell 别名
  # ---------------------------------------------------------------------------
  home.shellAliases = {
    ag = "pi";
    # 原 pi-init / pi-memory / pi-coding / pi-clean 别名已由 extensions-manager.ts 的
    # /exts 命令取代 (装配在会话内完成后自动 reload, 无需 shell 入口);
    # 不做 `pi -p "/exts … -y"` 薄别名: print 模式下若扩展加载失败, 该串会
    # 被当作普通 prompt 发给模型。
  };
}
