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
  };
}
