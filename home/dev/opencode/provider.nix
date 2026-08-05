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

  # --- 火山方舟 (Volcengine Ark) 配置 ---
  # 深度思考文档: https://www.volcengine.com/docs/82379/1449737
  # 模型列表:     https://www.volcengine.com/docs/82379/1330310
  # 模型价格:     https://www.volcengine.com/docs/82379/1544106
  volcengine = {
    npm = "@ai-sdk/openai-compatible";
    name = "VolcanoArk";
    env = [ "VOLCANO_ARK_API_KEY" ];
    whitelist = [
      "doubao-seed-2-0-code-preview-260215"
      "doubao-seed-2-0-lite-260215"
      "doubao-seed-2-0-pro-260215"
      "deepseek-v4-pro-260425"
      "deepseek-v4-flash-260425"
    ];
    options = {
      baseURL = "https://ark.cn-beijing.volces.com/api/v3";
      apiKey = "{env:VOLCANO_ARK_API_KEY}";
      timeout = 600000;
      headerTimeout = 600000;
      chunkTimeout = 60000;
    };

    models = {
      # =======================================================================
      # Doubao (豆包) Seed 2.0 系列 — 原生多模态模型
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
      #
      # 豆包 Seed 2.0 定价为三档阶梯价 (元/百万 token):
      #   [0, 32k]:     输入/缓存命中/输出
      #   (32k, 128k]:  输入/缓存命中/输出
      #   (128k, 256k]: 输入/缓存命中/输出
      # cost 字段使用最低档 (0-32k) 作为基准值, 完整阶梯详见注释
      # =======================================================================

      # --- doubao-seed-2-0-code-preview-260215 ---
      # 特化代码生成模型, 预览版
      "doubao-seed-2-0-code-preview-260215" = {
        name = "Doubao Seed Code Preview";
        family = "Doubao Seed 2.0";
        release_date = "2026-02-15";
        status = "beta";
        reasoning = true;
        tool_call = true;
        attachment = true;
        experimental = true;

        # 阶梯价: 3.2 / 4.8 / 9.6 → 缓存 0.64 / 0.96 / 1.92 → 输出 16.0 / 24.0 / 48.0
        cost = {
          input = 3.2;
          output = 16.0;
          cache_read = 0.64;
        };

        limit = {
          context = 262144;
          input = 229376;
          output = 131072;
        };

        modalities = {
          input = [ "text" "image" ];
          output = [ "text" ];
        };

        options = {
          temperature = 0.2;
          topP = 0.9;
        };

        variants = {
          "default" = { reasoningEffort = "medium"; };
          "deep-coding" = { reasoningEffort = "high"; };
        };
      };

      # --- doubao-seed-2-0-lite-260215 ---
      # 轻量级模型, 高性价比
      "doubao-seed-2-0-lite-260215" = {
        name = "Doubao Seed 2.0 Lite";
        family = "Doubao Seed 2.0";
        release_date = "2026-02-15";
        status = "active";
        reasoning = true;
        tool_call = true;
        attachment = true;
        experimental = false;

        # 阶梯价: 0.6 / 0.9 / 1.8 → 缓存 0.12 / 0.18 / 0.36 → 输出 3.6 / 5.4 / 10.8
        cost = {
          input = 0.6;
          output = 3.6;
          cache_read = 0.12;
        };

        limit = {
          context = 262144;
          input = 229376;
          output = 131072;
        };

        modalities = {
          input = [ "text" "image" ];
          output = [ "text" ];
        };

        options = {
          temperature = 0.2;
          topP = 0.95;
        };

        variants = {
          "default" = { reasoningEffort = "low"; };
          "thinking" = { reasoningEffort = "medium"; };
        };
      };

      # --- doubao-seed-2-0-pro-260215 ---
      # 旗舰模型, 支持 4 档推理强度
      "doubao-seed-2-0-pro-260215" = {
        name = "Doubao Seed 2.0";
        family = "Doubao Seed 2.0";
        release_date = "2026-02-15";
        status = "active";
        reasoning = true;
        tool_call = true;
        attachment = true;
        experimental = false;

        # 阶梯价: 3.2 / 4.8 / 9.6 → 缓存 0.64 / 0.96 / 1.92 → 输出 16.0 / 24.0 / 48.0
        cost = {
          input = 3.2;
          output = 16.0;
          cache_read = 0.64;
        };

        limit = {
          context = 262144;
          input = 229376;
          output = 131072;
        };

        modalities = {
          input = [ "text" "image" ];
          output = [ "text" ];
        };

        options = {
          temperature = 0.3;
          topP = 0.9;
          frequencyPenalty = 0.1;
        };

        variants = {
          "fast" = { reasoningEffort = "low"; };
          "default" = { reasoningEffort = "medium"; };
          "thinking" = { reasoningEffort = "high"; };
          "direct" = { reasoningEffort = "minimal"; };
        };
      };

      # =======================================================================
      # DeepSeek V4 (火山方舟托管) — 纯文本模型
      # 深度思考: https://www.volcengine.com/docs/82379/1449737
      #
      # 注意: 火山方舟仍为预览版 (260425), 尚未跟进 DeepSeek 官方 Flash 正式版 (2026-07-31)
      #
      # 对比 DeepSeek 官方 API, 火山方舟版额外支持 reasoning_effort 全档位:
      #   minimal / low / medium / high / max
      # (DeepSeek 官方仅 high/max, low/medium 会被映射为 high —— 详见下方官方 provider 注释)
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
        family = "DeepSeek V4 Ark";
        release_date = "2026-04-25";
        status = "active";
        reasoning = true;
        tool_call = true;
        attachment = false;
        experimental = false;

        cost = {
          input = 12.00;
          output = 24.00;
          cache_read = 1.00;
        };

        limit = {
          context = 1048576;
          input = 1048576;
          output = 393216;
        };

        modalities = {
          input = [ "text" ];
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
          "medium" = { reasoningEffort = "medium"; };
          "light" = { reasoningEffort = "low"; };
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
        family = "DeepSeek V4 Ark";
        release_date = "2026-04-25";
        status = "active";
        reasoning = true;
        tool_call = true;
        attachment = false;
        experimental = false;

        cost = {
          input = 1.00;
          output = 2.00;
          cache_read = 0.20;
        };

        limit = {
          context = 1048576;
          input = 1048576;
          output = 393216;
        };

        modalities = {
          input = [ "text" ];
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
          "medium" = { reasoningEffort = "medium"; };
          "fast" = {
            thinking = { type = "disabled"; };
          };
        };
      };
    };
  };
}
