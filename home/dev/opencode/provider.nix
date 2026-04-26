{
  # --- 火山方舟 (Volcengine Ark) 配置 ---
  volcengine = {
    # OpenCode 对 OpenAI-compatible provider 的标准写法
    npm = "@ai-sdk/openai-compatible";
    # 供应商在 OpenCode 界面里的显示名称
    name = "VolcanoArk";
    options = {
      # 火山方舟在线推理的 OpenAI-compatible 兼容接口
      baseURL = "https://ark.cn-beijing.volces.com/api/v3";
      # 使用 OpenCode 官方支持的 env 占位语法
      apiKey = "{env:VOLCANO_ARK_API_KEY}";
    };

    models = {
      "doubao-seed-2-0-code-preview-260215" = {
        # 在 /models 列表里显示的名称
        name = "Doubao Seed Code Preview";

        limit = {
          context = 262144; # 官方: 256K tokens 超长代码上下文
          output = 32768; # 官方: 最大 32K tokens 输出(不含思考内容)
        };

        # 默认参数优化: 专为编程场景深度优化
        options = {
          temperature = 0.2;
          topP = 0.9;
          frequencyPenalty = 0.0;
          presencePenalty = 0.0;
        };

        variants = {
          "default" = { reasoningLength = "medium"; }; # 代码生成首选
          "deep-coding" = { reasoningLength = "long"; }; # 复杂项目重构与调试
        };
      };

      "doubao-seed-2-0-lite-260215" = {
        name = "Doubao Seed 2.0 Lite";


        limit = {
          context = 262144; # 256K tokens 全系列标配
          output = 32768; # 最大 32K tokens 输出
        };

        # 默认参数优化: 适合日常代码编写与文档生成
        options = {
          temperature = 0.2;
          topP = 0.95;
        };

        variants = {
          "default" = { reasoningLength = "short"; }; # 极速模式, 性价比最高
          "thinking" = { reasoningLength = "medium"; }; # 平衡速度与深度
        };
      };

      "doubao-seed-2-0-pro-260215" = {
        name = "Doubao Seed 2.0";

        limit = {
          context = 262144; # 256K tokens 全系列标配
          output = 32768; # 最大 32K tokens 输出(不含思考内容)
        };

        # 默认参数优化: 适合深度推理与架构设计
        options = {
          temperature = 0.3;
          topP = 0.9;
          frequencyPenalty = 0.1;
        };

        # Seed 2.0 特有: 4 档思考长度支持
        variants = {
          "fast" = { reasoningLength = "short"; }; # 快速响应, 适合简单问答
          "default" = { reasoningLength = "medium"; }; # 均衡模式, 日常开发首选
          "thinking" = { reasoningLength = "long"; }; # 深度思考, 适合复杂问题
          "expert" = { reasoningLength = "very-long"; }; # 专家模式, 适合算法/数学
        };
      };
    };
  };

  # --- DeepSeek 官方 API 配置 ---
  deepseek = {
    npm = "@ai-sdk/openai-compatible";
    name = "DeepSeek";
    options = {
      baseURL = "https://api.deepseek.com/v1";
      apiKey = "{env:DEEPSEEK_API_KEY}";
    };

    models = {
      "deepseek-v4-pro" = {
        name = "DeepSeek V4 PRO";

        limit = {
          context = 1048576; # 1M tokens (约75万字)
          output = 393216; # 最大 384K tokens 输出
        };

        # 当模型在思考模式下生成包含tool_calls(工具调用)的助手消息时, DeepSeek API 要求客户端在同一轮对话的后续请求中, 必须将该助手消息的reasoning_content(思维链内容)字段原封不动地传回给 API
        interleaved = {
          field = "reasoning_content";
        };

        # 默认参数优化: 适合代码生成与架构设计
        options = {
          temperature = 0.3;
          topP = 0.9;
          frequencyPenalty = 0.1;
        };

        # V4 特有: 思考模式变体 (支持 reasoning_effort: low/high/max)
        variants = {
          "default" = { reasoningEffort = "low"; }; # 快速响应, 适合简单任务
          "thinking" = { reasoningEffort = "high"; }; # 深度思考, 适合复杂推理
          "max-thinking" = { reasoningEffort = "max"; }; # 最强推理, 适合数学/算法
        };
      };

      "deepseek-v4-flash" = {
        name = "DeepSeek V4 FLASH";

        limit = {
          context = 1048576; # 全系标配 1M 上下文
          output = 393216; # 同样支持 384K 最大输出
        };

        interleaved = {
          field = "reasoning_content";
        };

        # 默认参数优化: 适合快速代码补全与轻量任务
        options = {
          temperature = 0.2;
          topP = 0.95;
        };

        # 思考模式变体
        variants = {
          "default" = { reasoningEffort = "low"; }; # 极速模式, 性价比最高
          "thinking" = { reasoningEffort = "high"; }; # 平衡速度与深度
        };
      };
    };
  };
}
