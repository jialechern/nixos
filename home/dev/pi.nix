{ config, pkgs, ... }:

let
  # ---------------------------------------------------------------------------
  # pi 配置根目录: 与上游 CLI 默认值 ~/.pi/agent 一致
  # 显式写出 (而非依赖模块默认值), 防止上游将来变更默认路径影响本配置
  # ---------------------------------------------------------------------------
  piConfigDir = "${config.home.homeDirectory}/.pi/agent";

  # ===========================================================================
  # 火山方舟 (Volcengine Ark) 思考档位映射
  # 深度思考文档: https://www.volcengine.com/docs/82379/1449737
  # 方舟版 DeepSeek V4 支持 reasoning_effort 全档位: minimal/low/medium/high/max
  # (对比 DeepSeek 官方仅 low/high/max, 见下方官方模型注释)
  # 注: pi 的 "off" 档未显式映射 —— 方舟版需 thinking.type=disabled 才真正关闭思考,
  #     此处交由 pi 默认行为处理 (默认档位为 max, 不影响日常使用)
  # ===========================================================================
  arkDeepSeekThinking = {
    "minimal" = "minimal";
    "low" = "low";
    "medium" = "medium";
    "high" = "high";
    "xhigh" = null; # 方舟无此档位, 从 UI 中隐藏
    "max" = "max";
  };

  # 豆包 (Doubao) 仅 4 档: minimal < low < medium < high, 不支持 max
  # 官方文档说明: reasoning_effort = minimal 时等同于关闭思考, 直接回答
  doubaoThinking = {
    "off" = "minimal"; # 豆包以 minimal 档实现"关闭思考"
    "minimal" = "minimal";
    "low" = "low";
    "medium" = "medium";
    "high" = "high";
    "xhigh" = null;
    "max" = null;
  };

  # 豆包 Seed 2.0 系列通用模型参数 (上下文/输出上限源自 opencode/provider.nix)
  mkDoubaoModel = { id, name }: {
    inherit id name;
    reasoning = true;
    input = [ "text" "image" ]; # 原生多模态模型
    contextWindow = 262144;
    maxTokens = 131072;
    thinkingLevelMap = doubaoThinking;
  };

  # 方舟版 DeepSeek V4 通用模型参数
  mkArkDeepSeekModel = { id, name }: {
    inherit id name;
    reasoning = true;
    input = [ "text" ];
    contextWindow = 1048576;
    maxTokens = 393216;
    thinkingLevelMap = arkDeepSeekThinking;
  };
in
{
  programs.pi-coding-agent = {
    # 必须启用才会安装软件包并生成配置
    enable = true;

    # 使用包装过后的软件包: 启动时加载 sops 生成的密钥文件 (参照 opencode.nix 的做法)
    # 密钥由 sops.nix 的 "pi-secrets.env" 模板生成, 文件不存在时静默跳过
    package = pkgs.symlinkJoin {
      name = "pi-coding-agent-wrapped";
      paths = [ pkgs.pi-coding-agent ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/pi \
          --run '
            SECRET_FILE="$HOME/.config/pi/secrets.env"
            if [ -f "$SECRET_FILE" ]; then
              set -a
              source "$SECRET_FILE"
              set +a
            fi
          '
      '';
    };

    # 扩展包运行时依赖: pi install npm:... 安装扩展 (如 @termdraw/pi) 需要 npm 与 bun
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
    ];

    # 配置目录 (见文件头注释)
    configDir = piConfigDir;

    # -------------------------------------------------------------------------
    # settings.json: ~/.pi/agent/settings.json
    # 文档: https://pi.dev/docs/latest/settings
    # -------------------------------------------------------------------------
    settings = {
      # --- 模型与思考 ---
      defaultProvider = "deepseek"; # 默认提供商: DeepSeek 官方开放平台
      defaultModel = "deepseek-v4-flash"; # 默认模型: DeepSeek V4 Flash (2026-07-31 官方正式发布)
      defaultThinkingLevel = "max"; # 默认思考等级: 最高级 (官方支持 low/high/max, max 直通)

      # --- UI 与显示 ---
      theme = "catppuccin-mocha-mauve"; # 自定义 Catppuccin Mocha (mauve 强调色) 主题

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

      # --- Ctrl+P 循环切换的模型白名单 (模式匹配, 同 --models 格式) ---
      enabledModels = [
        "deepseek-*"
        "doubao-seed-2-0-*"
      ];

      # --- 扩展包资源 (npm/git 包) ---
      # 后续安装 pi 扩展时在此声明, 例如: "npm:@termdraw/pi"
      packages = [ ];

      # --- 网络代理 (可选) ---
      # 国内访问海外 API 时可取消下面注释 (本机透明代理默认 127.0.0.1:20172):
      # httpProxy = "http://127.0.0.1:20172";
    };

    # -------------------------------------------------------------------------
    # keybindings.json: ~/.pi/agent/keybindings.json
    # 文档: https://pi.dev/docs/latest/keybindings
    # 风格: 编辑区为 vim 移动语义 + ctrl 修饰键 (ctrl+h/l/b/w 对应 vim 的 h/l/b/w),
    #       会话管理仿 opencode 的 <leader> 键位, 改用 ctrl+shift 前缀
    # 注意: 对某个动作自定义键位会整体替换其默认键位, 故列表中保留不冲突的
    #       常用默认键 (up/down/enter/escape 等), 与 vim 习惯不符的默认键则有意重绑
    # -------------------------------------------------------------------------
    keybindings = {
      # --- 编辑区光标移动 (vim/neovim 风格) ---
      "tui.editor.cursorUp" = [ "up" "ctrl+p" ]; # 上移
      "tui.editor.cursorDown" = [ "down" "ctrl+n" ]; # 下移
      "tui.editor.cursorLeft" = [ "left" "ctrl+h" ]; # 左移
      "tui.editor.cursorRight" = [ "right" "ctrl+l" ]; # 右移
      "tui.editor.cursorWordLeft" = [ "ctrl+left" "ctrl+b" ]; # 单词左移 (vim b 的 ctrl 版本)
      "tui.editor.cursorWordRight" = [ "ctrl+right" "ctrl+w" ]; # 单词右移 (vim w 的 ctrl 版本; 原删词默认键 ctrl+w 改作此用)

      # --- 编辑区删除 (vim 风格) ---
      # 注: deleteCharBackward/Forward 的默认键 ctrl+h/ctrl+d 已分别让位给
      #     上方的 cursorLeft (vim h) 与下方的 deleteWordForward (vim dw),
      #     故此处显式重绑为单键, 避免同键匹配两个动作
      "tui.editor.deleteCharBackward" = [ "backspace" ]; # 删除前一字符
      "tui.editor.deleteCharForward" = [ "delete" ]; # 删除后一字符
      "tui.editor.deleteWordBackward" = [ "ctrl+backspace" ]; # 删除前一个单词 (vim 插入模式 ctrl+w; 此处绑定终端等效键 ctrl+backspace)
      "tui.editor.deleteWordForward" = [ "ctrl+d" "alt+delete" ]; # 删除后一个单词 (vim dw)
      "tui.editor.deleteToLineStart" = "ctrl+u"; # 删除到行首
      # "tui.editor.deleteToLineEnd" = "ctrl+k"; # 删除到行尾

      # --- 编辑区撤销/粘贴 ---
      "tui.editor.undo" = "ctrl+-"; # 撤销
      "tui.editor.yank" = "ctrl+y"; # 粘贴最近删除内容
      "tui.editor.yankPop" = "alt+y"; # 循环切换删除历史

      # --- 输入 ---
      "tui.input.newLine" = [ "shift+enter" "ctrl+j" ]; # 插入换行
      "tui.input.submit" = "enter"; # 提交输入
      "tui.input.tab" = "tab"; # Tab / 自动补全

      # --- 选择列表 (模型选择器 /model、会话恢复等通用列表) ---
      "tui.select.up" = [ "up" "ctrl+p" ]; # 上移
      "tui.select.down" = [ "down" "ctrl+n" ]; # 下移
      "tui.select.confirm" = "enter"; # 确认选择
      "tui.select.cancel" = [ "escape" ]; # 取消选择

      # --- 会话管理 (仿 opencode 的 <leader> 键位) ---
      "app.session.new" = "ctrl+shift+n"; # 新建会话 (/new)
      "app.session.resume" = "ctrl+shift+r"; # 打开会话恢复选择器 (/resume)
      "app.session.tree" = "ctrl+shift+t"; # 打开会话树 (/tree)
      "app.session.fork" = "ctrl+shift+f"; # 分叉当前会话 (/fork)

      # --- 应用操作 ---
      "app.interrupt" = "escape"; # 取消/中止
      "app.exit" = "ctrl+q"; # 退出 (输入为空时)
      "app.editor.external" = "ctrl+shift+e"; # 在外部编辑器中撰写
      "app.model.select" = "ctrl+\\"; # 打开模型选择器
      "app.model.cycleForward" = "ctrl+/"; # 循环到下一个模型
      "app.model.cycleBackward" = "shift+ctrl+/"; # 循环到上一个模型
      "app.thinking.cycle" = "shift+tab"; # 循环思考等级
      "app.thinking.toggle" = "ctrl+t"; # 折叠/展开思考块
      "app.message.copy" = "ctrl+x"; # 复制最后一条助手消息
      "app.message.followUp" = "alt+enter"; # 排队跟进消息
      "app.message.dequeue" = "alt+up"; # 撤回排队消息到输入框
    };

    # -------------------------------------------------------------------------
    # models.json: ~/.pi/agent/models.json
    # 自定义模型提供商文档: https://pi.dev/docs/latest/models
    # -------------------------------------------------------------------------
    models = {
      providers = {
        # =====================================================================
        # 火山方舟 (Volcengine Ark) — 自定义提供商
        # 模型列表: https://www.volcengine.com/docs/82379/1330310
        # 与 home/dev/opencode/provider.nix 中的 volcengine 配置保持一致
        # 注意: 方舟价格以人民币计价, pi 成本按 USD/百万 token 显示, 故此处不填 cost 避免误导
        # =====================================================================
        volcengine = {
          baseUrl = "https://ark.cn-beijing.volces.com/api/v3";
          api = "openai-completions";
          apiKey = "$VOLCANO_ARK_API_KEY"; # 由 ~/.config/pi/secrets.env (sops) 注入
          # 方舟不支持 developer role, 系统提示词以 system role 发送
          compat = {
            supportsDeveloperRole = false;
          };
          models = [
            # --- doubao-seed-2-0-code-preview-260215 (特化代码生成, 预览版) ---
            (mkDoubaoModel {
              id = "doubao-seed-2-0-code-preview-260215";
              name = "Doubao Seed 2.0 Code Preview";
            })

            # --- doubao-seed-2-0-lite-260215 (轻量级, 高性价比) ---
            (mkDoubaoModel {
              id = "doubao-seed-2-0-lite-260215";
              name = "Doubao Seed 2.0 Lite";
            })

            # --- doubao-seed-2-0-pro-260215 (旗舰, 4 档推理强度) ---
            (mkDoubaoModel {
              id = "doubao-seed-2-0-pro-260215";
              name = "Doubao Seed 2.0 Pro";
            })

            # --- deepseek-v4-pro-260425 (方舟托管, 预览版) ---
            (mkArkDeepSeekModel {
              id = "deepseek-v4-pro-260425";
              name = "DeepSeek V4 PRO (Ark)";
            })

            # --- deepseek-v4-flash-260425 (方舟托管, 预览版) ---
            (mkArkDeepSeekModel {
              id = "deepseek-v4-flash-260425";
              name = "DeepSeek V4 Flash (Ark)";
            })
          ];
        };

        # =====================================================================
        # DeepSeek 官方开放平台 — 内置 provider 补充
        # 官方手册: https://api-docs.deepseek.com/guides/thinking_mode
        # 思考档位: 仅 low/high/max (minimal/medium 无效, xhigh 服务端映射为 high)
        #   请求档位 low → flash 直通 / pro 映射 high; high → high; max → max
        # 关闭思考: thinking.type = "disabled" (内置 provider 已处理)
        # 仅声明 models 数组, 内置模型保留、同 id 覆盖, 认证仍走 DEEPSEEK_API_KEY
        # =====================================================================
        deepseek = {
          models = [
            # --- deepseek-v4-flash: 2026-07-31 官方正式发布 (默认模型) ---
            # 官方 Change Log (2026-07-31): V4-Flash-0731 正式发布上线, API 模型名不变
            #   https://api-docs.deepseek.com/updates
            # 284B 总参 / 13B 激活, MoE 架构; agent 基准已超 V4-Pro-Preview, 性价比首选
            {
              id = "deepseek-v4-flash";
              name = "DeepSeek V4 Flash";
              reasoning = true;
              input = [ "text" ];
              contextWindow = 1048576; # 官方 1M 上下文
              maxTokens = 393216; # 官方最大输出 384K (393216 = 384 * 1024)
              # 官方映射 (flash 专属): low→low, high→high, xhigh→high, max→max (minimal/medium 无效)
              thinkingLevelMap = {
                "minimal" = null;
                "low" = "low";
                "medium" = null;
                "high" = "high";
                "xhigh" = null; # 服务端等效于 high, 隐藏避免误解
                "max" = "max";
              };
              # 官方定价 (per 1M tokens, 2026-08-03 核实): 输入 $0.14 / 缓存命中 $0.0028 / 输出 $0.28
              # 参考: https://api-docs.deepseek.com/quick_start/pricing
              cost = {
                input = 0.14;
                output = 0.28;
                cacheRead = 0.0028;
                cacheWrite = 0; # 官方无缓存写入费用
              };
            }

            # --- deepseek-v4-pro: 旗舰编程与推理模型 ---
            # 1.6T 总参 / 49B 激活, MoE 架构
            {
              id = "deepseek-v4-pro";
              name = "DeepSeek V4 PRO";
              reasoning = true;
              input = [ "text" ];
              contextWindow = 1048576;
              maxTokens = 393216;
              # 官方映射: low→high, high→high, xhigh→high, max→max (minimal/medium 无效)
              # (官方将于 2026-08 初更新 pro 的映射, 届时以官方手册为准)
              thinkingLevelMap = {
                "minimal" = null;
                "low" = "low"; # 服务端实际映射为 high, 与官方表保持一致
                "medium" = null;
                "high" = "high";
                "xhigh" = null; # 服务端等效于 high, 隐藏避免误解
                "max" = "max";
              };
              # 官方定价 (per 1M tokens, 2026-08-03 核实): 输入 $0.435 / 缓存命中 $0.003625 / 输出 $0.87
              # 参考: https://api-docs.deepseek.com/quick_start/pricing
              cost = {
                input = 0.435;
                output = 0.87;
                cacheRead = 0.003625;
                cacheWrite = 0; # 官方无缓存写入费用
              };
            }
          ];
        };
      };
    };

    # -------------------------------------------------------------------------
    # AGENTS.md: 全局上下文 (作用于所有项目)
    # 文档: https://pi.dev/docs/latest/quickstart (Give pi project instructions)
    # 修改后需 /reload 或重启生效
    # -------------------------------------------------------------------------
    context = ./pi/AGENTS.md;
  };

  # ---------------------------------------------------------------------------
  # 自定义主题: Catppuccin Mocha (mauve 强调色), 与系统主题风格统一
  # 文档: https://pi.dev/docs/latest/themes (51 个必填 token, 热重载生效)
  # ---------------------------------------------------------------------------
  home.file."${piConfigDir}/themes/catppuccin-mocha-mauve.json".source =
    ./pi/catppuccin-mocha-mauve.json;
}
