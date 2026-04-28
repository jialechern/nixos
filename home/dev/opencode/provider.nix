{
  # ===========================================================================
  # 配置要点:
  #   - npm:  指明使用的 AI SDK provider 包, 此处用通用的 OpenAI-compatible 适配器
  #   - options:  provider 级别的全局选项 (baseURL, apiKey, timeout 等)
  #   - models:  模型列表, 每个模型的 options/variants 会覆盖 provider 级别
  #   - variants: 模型变体, 用于同一模型的不同推理模式 (思考/非思考/推理强度)
  # ===========================================================================

  # --- 火山方舟 (Volcengine Ark) 配置 ---
  volcengine = {
    npm = "@ai-sdk/openai-compatible";
    name = "VolcanoArk";
    options = {
      # 火山方舟在线推理的 OpenAI-compatible 兼容接口
      baseURL = "https://ark.cn-beijing.volces.com/api/v3";
      apiKey = "{env:VOLCANO_ARK_API_KEY}";
    };

    models = {
      # --- doubao-seed-2-0-code-preview-260215 ---
      # 特化代码生成模型, 预览版
      "doubao-seed-2-0-code-preview-260215" = {
        name = "Doubao Seed Code Preview";

        limit = {
          context = 262144; # 256K tokens 超长代码上下文
          output = 32768; # 最大 32K tokens 输出
        };

        # 默认参数: 专为编程场景深度优化
        # 注: 豆包模型深度思考模式默认开启, temperature/topP 等参数在思考模式下可能不生效
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

      # --- doubao-seed-2-0-lite-260215 ---
      # 轻量级模型, 高性价比
      "doubao-seed-2-0-lite-260215" = {
        name = "Doubao Seed 2.0 Lite";

        limit = {
          context = 262144; # 256K tokens 全系列标配
          output = 32768; # 最大 32K tokens 输出
        };

        options = {
          temperature = 0.2;
          topP = 0.95;
        };

        variants = {
          "default" = { reasoningLength = "short"; }; # 极速模式
          "thinking" = { reasoningLength = "medium"; }; # 平衡速度与深度
        };
      };

      # --- doubao-seed-2-0-pro-260215 ---
      # 旗舰模型, 支持 4 档思考长度
      "doubao-seed-2-0-pro-260215" = {
        name = "Doubao Seed 2.0";

        limit = {
          context = 262144; # 256K tokens 全系列标配
          output = 32768; # 最大 32K tokens 输出
        };

        options = {
          temperature = 0.3;
          topP = 0.9;
          frequencyPenalty = 0.1;
        };

        # 4 档思考长度: short < medium < long < very-long
        variants = {
          "fast" = { reasoningLength = "short"; }; # 快速响应
          "default" = { reasoningLength = "medium"; }; # 均衡模式, 日常首选
          "thinking" = { reasoningLength = "long"; }; # 深度思考
          "expert" = { reasoningLength = "very-long"; }; # 专家模式, 算法/数学
        };
      };
    };
  };

  # --- DeepSeek 官方 API 配置 ---
  # DeepSeek V4 系列: 1M 上下文 + 双模式(思考/非思考)
  # 定价 (per 1M tokens):
  #   V4 Pro:  input $0.435(cache miss) / $0.003625(cache hit) / output $0.87
  #   V4 Flash: input $0.14(cache miss)  / $0.0028(cache hit)    / output $0.28
  # 官方文档: https://api-docs.deepseek.com/guides/thinking_mode
  #         https://api-docs.deepseek.com/quick_start/pricing
  deepseek = {
    npm = "@ai-sdk/openai-compatible";
    name = "DeepSeek";
    options = {
      # DeepSeek API 的 OpenAI 兼容端点 (v1)
      baseURL = "https://api.deepseek.com/v1";
      apiKey = "{env:DEEPSEEK_API_KEY}";
      # 请求超时(ms): V4 深度推理可能耗时较长, OpenCode 默认 300000, 此处放宽至 600000
      timeout = 600000;
      # 流式响应的 chunk 超时(ms): 防止长时间无数据导致连接中断
      chunkTimeout = 60000;
    };

    models = {
      # =======================================================================
      # deepseek-v4-pro (1.6T 总参 / 49B 激活参数, MoE 架构)
      # =======================================================================
      "deepseek-v4-pro" = {
        name = "DeepSeek V4 PRO";

        limit = {
          context = 1048576; # 1M tokens (官方全系标配, ≈75 万汉字)
          output = 393216; # 384K tokens (官方最大输出, = 384 × 1024)
        };

        # 思考模式下工具调用后, API 要求后续请求必须将 assistant 消息中的
        # reasoning_content 字段原样传回, 否则返回 HTTP 400 错误.
        # interleaved 告诉 OpenCode 自动处理此字段的拼接与回传.
        interleaved = {
          field = "reasoning_content";
        };

        # ---- 默认选项 ----
        # V4 默认启用思考模式 (thinking mode). 在该模式下:
        #   reasoning_effort: 可选 "high"(默认) 或 "max"
        #     - "low"/"medium" 会被 API 映射为 "high"
        #     - OpenCode agent 任务的 effort 会被 API 自动提升为 "max"
        #   temperature / topP / frequencyPenalty / presencePenalty: 不生效
        #     设置这些参数不会报错, 但 API 会忽略它们
        #   logprobs / top_logprobs: 不支持, 会报错
        #
        # 非思考模式 (thinking.type = disabled):
        #   所有标准参数恢复正常, DeepSeek 官方推荐:
        #     - Coding/Math:       temperature = 0.0
        #     - Data Analysis:     temperature = 1.0
        #     - General Chat:      temperature = 1.3
        #     - Creative Writing:  temperature = 1.5
        options = {
          temperature = 0.0; # 编码场景官方推荐值; 思考模式下不生效
          topP = 0.9;
        };

        variants = {
          # 思考模式(默认): reasoning_effort = high
          # 适合日常编程、代码审查、文档生成
          "default" = { reasoningEffort = "high"; };

          # 最强推理: reasoning_effort = max
          # 适合复杂算法、数学证明、大型重构、架构决策
          # 注: OpenCode agent 任务会被 API 自动提升为 max,
          #     故此变体与 default 在 agent 场景下效果可能相同
          "max-thinking" = { reasoningEffort = "max"; };

          # 非思考模式: 关闭链式推理, 响应最快, 适合简单补全/翻译/轻量任务
          #   - temperature/topP/frequencyPenalty 等标准参数恢复生效
          #   - 不产生 reasoning_content, 无需 interleaved 处理
          # 注意: thinking 参数需通过 extra_body 传递, OpenCode/@ai-sdk 的底层支持
          #       取决于具体版本, 若无效可尝试改用 OpenCode 内置的 deepseek provider
          "fast" = {
            thinking = { type = "disabled"; };
          };
        };
      };

      # =======================================================================
      # deepseek-v4-flash (284B 总参 / 13B 激活参数, MoE 架构)
      # 定位: 快速/经济型, 推理能力接近 Pro, 简单 agent 任务与 Pro 持平
      # =======================================================================
      "deepseek-v4-flash" = {
        name = "DeepSeek V4 FLASH";

        limit = {
          context = 1048576; # 1M tokens (全系标配)
          output = 393216; # 384K tokens (与 Pro 相同)
        };

        interleaved = {
          field = "reasoning_content";
        };

        # Flash 参数: 与 Pro 设置一致, 说明同上
        options = {
          temperature = 0.0;
          topP = 0.9;
        };

        variants = {
          # 思考模式(默认): 日常任务首选, 平衡质量与速度
          "default" = { reasoningEffort = "high"; };

          # 最强推理: 适合需要深度分析但追求性价比的场景
          "max-thinking" = { reasoningEffort = "max"; };

          # 非思考模式: 极致速度, 简单任务性价比最高
          "fast" = {
            thinking = { type = "disabled"; };
          };
        };
      };
    };
  };
}
