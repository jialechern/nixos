{
  # ===========================================================================
  # 配置要点:
  #   - npm:  指明使用的 AI SDK provider 包, 此处用通用的 OpenAI-compatible 适配器
  #   - options:  provider 级别的全局选项 (baseURL, apiKey, timeout 等)
  #   - models:  模型列表, 每个模型的 options/variants 会覆盖 provider 级别
  #   - variants: 模型变体, 用于同一模型的不同推理模式 (思考/非思考/推理强度)
  # ===========================================================================

  # --- 火山方舟 (Volcengine Ark) 配置 ---
  # 深度思考文档: https://www.volcengine.com/docs/82379/1449737
  volcengine = {
    npm = "@ai-sdk/openai-compatible";
    name = "VolcanoArk";
    options = {
      # 火山方舟在线推理的 OpenAI-compatible 兼容接口
      baseURL = "https://ark.cn-beijing.volces.com/api/v3";
      apiKey = "{env:VOLCANO_ARK_API_KEY}";
      # 请求超时(ms): DeepSeek V4 深度推理可能耗时数分钟, 与官方 provider 保持一致
      timeout = 600000;
      # 流式响应的 chunk 超时(ms): 防止长时间无数据导致连接中断
      chunkTimeout = 60000;
    };

    models = {
      # =======================================================================
      # Doubao (豆包) Seed 2.0 系列
      # 文档: https://www.volcengine.com/docs/82379/1330310
      #
      # Doubao 深度思考默认开启 (thinking.type = enabled), 支持 4 档推理强度:
      #   minimal (关闭思考) < low < medium (默认) < high
      # Doubao 不支持 max (仅 DeepSeek V4 支持)
      #
      # 思考模式下 temperature/topP/frequencyPenalty/presencePenalty 不生效
      # reasoning_effort = minimal 时等同于关闭思考, 直接回答
      # 注意: 若显式设置 thinking.type = disabled,
      #       则 reasoning_effort 仅合法取值为 minimal, 其他值会报错
      # =======================================================================

      # --- doubao-seed-2-0-code-preview-260215 ---
      # 特化代码生成模型, 预览版
      "doubao-seed-2-0-code-preview-260215" = {
        name = "Doubao Seed Code Preview";

        limit = {
          context = 262144; # 256K tokens 上下文
          output = 131072; # 128K tokens 最大输出
        };

        # 思考模式下 temperature/topP 不生效, 设置不会报错但会被忽略
        options = {
          temperature = 0.2;
          topP = 0.9;
        };

        variants = {
          # 均衡模式(默认): 代码生成首选, 兼顾质量与速度
          "default" = { reasoningEffort = "medium"; };
          # 深度分析: 复杂项目重构与调试
          "deep-coding" = { reasoningEffort = "high"; };
        };
      };

      # --- doubao-seed-2-0-lite-260215 ---
      # 轻量级模型, 高性价比
      "doubao-seed-2-0-lite-260215" = {
        name = "Doubao Seed 2.0 Lite";

        limit = {
          context = 262144; # 256K tokens
          output = 131072; # 128K tokens 最大输出
        };

        # Lite 本身侧重速度, 思考模式下的 temperature/topP 不生效
        options = {
          temperature = 0.2;
          topP = 0.95;
        };

        variants = {
          # 轻量思考(默认): Lite 主打极速, 推理强度不宜过高
          "default" = { reasoningEffort = "low"; };
          # 均衡模式: 适当增加推理深度, 应对中等复杂度任务
          "thinking" = { reasoningEffort = "medium"; };
        };
      };

      # --- doubao-seed-2-0-pro-260215 ---
      # 旗舰模型, 支持 4 档推理强度
      "doubao-seed-2-0-pro-260215" = {
        name = "Doubao Seed 2.0";

        limit = {
          context = 262144; # 256K tokens
          output = 131072; # 128K tokens 最大输出
        };

        # 思考模式下 temperature/topP/frequencyPenalty 不生效
        options = {
          temperature = 0.3;
          topP = 0.9;
          frequencyPenalty = 0.1;
        };

        # 4 档推理强度: low < medium(默认) < high; minimal = 关闭思考
        variants = {
          # 轻量思考: 快速响应
          "fast" = { reasoningEffort = "low"; };
          # 均衡模式(默认): 日常编码、通用任务首选
          "default" = { reasoningEffort = "medium"; };
          # 深度分析: 复杂推理、算法、数学
          "thinking" = { reasoningEffort = "high"; };
          # 关闭思考: 极致速度, 适合简单翻译/补全/格式转换
          "direct" = { reasoningEffort = "minimal"; };
        };
      };

      # =======================================================================
      # DeepSeek V4 (火山方舟托管)
      # 模型列表: https://www.volcengine.com/docs/82379/1330310
      # 深度思考: https://www.volcengine.com/docs/82379/1449737
      # 模型价格: https://www.volcengine.com/docs/82379/1544106
      #
      # 对比 DeepSeek 官方 API, 火山方舟版额外支持 reasoning_effort 全档位:
      #   minimal / low / medium / high / max
      # (DeepSeek 官方仅 high/max, low/medium 会被映射为 high)
      #
      # 定价 (在线推理, 元/百万token):
      #   V4 Pro:  输入 ¥12.00 / 缓存命中 ¥1.00 / 输出 ¥24.00
      #   V4 Flash: 输入 ¥1.00  / 缓存命中 ¥0.20 / 输出 ¥2.00
      #
      # 两者默认开启深度思考 (thinking.type = enabled), 均可设为 disabled
      # =======================================================================

      # --- deepseek-v4-pro-260425 ---
      # 1.6T 总参 / 49B 激活参数, MoE 架构
      # 旗舰编程与推理模型, 世界知识/数学/STEM 表现最强
      "deepseek-v4-pro-260425" = {
        name = "DeepSeek V4 PRO";

        limit = {
          context = 1048576; # 1M tokens (1024K) 超长上下文
          output = 393216; # 384K tokens 最大输出 (1024 × 384)
        };

        # 工具调用后需将 assistant 消息中的 reasoning_content 原样传回 API
        # 否则返回 HTTP 400. interleaved 告诉 OpenCode 自动处理此字段
        interleaved = {
          field = "reasoning_content";
        };

        # 思考模式下 temperature/topP/frequencyPenalty/presencePenalty 不生效
        # 设置不会报错, 但 API 会忽略. 非思考模式 (fast 变体) 下全部正常生效
        options = {
          temperature = 0.0; # 编码场景官方推荐; 思考模式下不生效
          topP = 0.9;
        };

        variants = {
          # 高推理强度(默认): 日常编码、代码审查、文档生成首选
          "default" = { reasoningEffort = "high"; };

          # 最强推理: 复杂算法、数学证明、大型重构、架构决策
          # 注: OpenCode agent 任务会被自动提升为 max
          "max-thinking" = { reasoningEffort = "max"; };

          # 中等推理 (方舟独有): 速度与深度平衡, 适合中等复杂度问题
          # DeepSeek 官方 API 不支持此档位 (会被映射为 high)
          "medium" = { reasoningEffort = "medium"; };

          # 低推理强度 (方舟独有): 快速推理但仍保留思考链路
          "light" = { reasoningEffort = "low"; };

          # 非思考模式: 关闭链式推理, 响应最快, 适合简单补全/翻译/轻量任务
          # 此模式下 temperature/topP 等标准参数恢复生效
          "fast" = {
            thinking = { type = "disabled"; };
          };
        };
      };

      # --- deepseek-v4-flash-260425 ---
      # 284B 总参 / 13B 激活参数, MoE 架构
      # 推理能力接近 Pro, 但速度更快、成本更低 (约 1/10)
      # 简单 agent 任务效果与 Pro 持平, 性价比首选
      "deepseek-v4-flash-260425" = {
        name = "DeepSeek V4 FLASH";

        limit = {
          context = 1048576; # 1M tokens (全系标配)
          output = 393216; # 384K tokens (与 Pro 相同)
        };

        interleaved = {
          field = "reasoning_content";
        };

        options = {
          temperature = 0.0;
          topP = 0.9;
        };

        variants = {
          # 高推理强度(默认): 日常编程任务首选, 平衡质量与速度
          "default" = { reasoningEffort = "high"; };

          # 最强推理: 需要深度分析但追求性价比的场景
          "max-thinking" = { reasoningEffort = "max"; };

          # 中等推理 (方舟独有): 快速代码补全/简单修复
          "medium" = { reasoningEffort = "medium"; };

          # 非思考模式: 极致速度, 简单任务性价比最高
          "fast" = {
            thinking = { type = "disabled"; };
          };
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
