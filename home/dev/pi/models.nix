{
  providers = {
    # =====================================================================
    # DeepSeek 官方 API
    # 认证: auth 由 /login deepseek 写入 ~/.pi/agent/auth.json, 故不写 apiKey
    # base_url: https://api.deepseek.com (OpenAI 兼容)
    # =====================================================================
    deepseek = {
      baseUrl = "https://api.deepseek.com";
      api = "openai-completions";

      models = [
        # --- deepseek-flash (2026-09-10 上线, 即 V4.1 Flash 的正式 API 名称) ---
        # 线上 /models 目前只返回 deepseek-flash 与 deepseek-v4-pro 两项, 旧名
        # deepseek-v4-flash 与内测 ID deepseek-v4.1-flash-expires-on-0910 均被
        # 重定向到同一后端; 该模型原生多模态 (实测可读图)。
        # 官方文档与 pi.dev 远程目录尚未收录, 故在此本地补齐。
        # 上下文 / 输出上限沿用同 provider 内置条目公布的 1M / 384K: 新模型尚未
        # 被官方价格页收录, 无更权威数值可依。不填 cost —— 单价未公布, 留空
        # 好过按 V4-Flash 旧价误导显示。
        {
          id = "deepseek-flash";
          name = "DeepSeek Flash (V4.1)";
          reasoning = true;
          input = [ "text" "image" ]; # 原生多模态
          contextWindow = 1000000;
          maxTokens = 384000;
          # 官方仅支持 low / high / max 三档, 其余置 null 从 UI 中隐藏;
          # 关闭思考交由 thinkingFormat = "deepseek" 发送 thinking.type = "disabled"
          # 实现 (2026-09-10 实测该模型支持)。
          thinkingLevelMap = {
            "minimal" = null;
            "low" = "low";
            "medium" = null;
            "high" = "high";
            "xhigh" = null;
            "max" = "max";
          };
          # compat 与内置 deepseek 条目保持一致
          compat = {
            supportsStore = false;
            supportsDeveloperRole = false;
            maxTokensField = "max_tokens";
            requiresReasoningContentOnAssistantMessages = true;
            thinkingFormat = "deepseek";
          };
        }
      ];
    };
  };
}
