{
  # ===========================================================================
  # 配置要点:
  #   - npm:  指明使用的 AI SDK provider 包, 此处用通用的 OpenAI-compatible 适配器
  #   - options:  provider 级别的全局选项 (baseURL, apiKey, timeout 等)
  #   - models:  模型列表, 每个模型的 options/variants 会覆盖 provider 级别
  #   - variants: 模型变体, 用于同一模型的不同推理模式 (思考/非思考/推理强度)
  #   - env:    该 provider 依赖的环境变量列表, 用于校验
  #   - whitelist: 仅展示列表中的模型, 隐藏账号下其他模型
  #
  # status 字段仅接受 opencode schema 定义的四个枚举值:
  #   "alpha" | "beta" | "deprecated" | "active"
  # ===========================================================================

  # --- DeepSeek 官方 API ---
  # API 文档:   https://api-docs.deepseek.com/
  # 模型与价格: https://api-docs.deepseek.com/zh-cn/quick_start/pricing
  # 思考模式:   https://api-docs.deepseek.com/zh-cn/guides/thinking_mode
  #
  # 官方 API 与 OpenAI 兼容, 故用 @ai-sdk/openai-compatible 适配器。
  # 认证依赖 DEEPSEEK_API_KEY 环境变量 (由 ~/.config/opencode/secrets.env 注入),
  # 该变量目前尚未配置, 配好前本 provider 不可用。
  deepseek = {
    npm = "@ai-sdk/openai-compatible";
    name = "DeepSeek";
    env = [ "DEEPSEEK_API_KEY" ];
    whitelist = [ "deepseek-flash" ];
    options = {
      baseURL = "https://api.deepseek.com";
      apiKey = "{env:DEEPSEEK_API_KEY}";
      timeout = 600000;
      headerTimeout = 600000;
      chunkTimeout = 60000;
    };

    models = {
      # =======================================================================
      # deepseek-flash — 2026-09-10 上线, 即 V4.1 Flash 的正式 API 名称
      #
      # 线上 /models 目前只返回 deepseek-flash 与 deepseek-v4-pro 两项, 旧名
      # deepseek-v4-flash 与内测 ID deepseek-v4.1-flash-expires-on-0910 均被
      # 重定向到同一后端。
      #
      # 原生多模态 (实测可读图), 官方思考档位只有三档: low < high < max
      # (无 minimal / medium), 关闭思考由 thinking.type = "disabled" 实现。
      #
      # 不填 cost —— 官方价格页尚未收录该模型, 留空好过按 V4-Flash 旧价误导显示
      # 上下文 / 输出上限沿用 V4-Flash 公布的 1M / 384K (新值官方未公布)
      # =======================================================================
      "deepseek-flash" = {
        name = "DeepSeek Flash (V4.1)";
        family = "DeepSeek V4.1";
        release_date = "2026-09-10";
        status = "active";
        reasoning = true;
        tool_call = true;
        attachment = true;
        experimental = false;

        limit = {
          context = 1000000;
          input = 1000000;
          output = 384000;
        };

        modalities = {
          input = [ "text" "image" ];
          output = [ "text" ];
        };

        interleaved = {
          field = "reasoning_content";
        };

        options = {
          temperature = 0.0;
          topP = 0.9;
        };

        variants = {
          "default" = { reasoningEffort = "high"; };
          "max-thinking" = { reasoningEffort = "max"; };
          "light" = { reasoningEffort = "low"; };
          "fast" = {
            thinking = { type = "disabled"; };
          };
        };
      };
    };
  };
}
