let
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
            "low" = "low"; # pi 发送 reasoning_effort=low, 服务端内部将 low 映射为 high
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
}
