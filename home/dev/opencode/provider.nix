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

  # --- DeepSeek 官方 API 配置 ---
  # DeepSeek V4 系列: 1M 上下文 + 双模式(思考/非思考)
  # 官方 pricing 页面 (2026-08-01 核实): https://api-docs.deepseek.com/quick_start/pricing
  #   - Base URL (OpenAI 格式):    https://api.deepseek.com  (含 /v1 别名亦可用, 但以官方最新文档为准)
  #   - Base URL (Anthropic 格式): https://api.deepseek.com/anthropic
  #   - 并发限额: Flash 2500 / Pro 500
  #   - Chat Prefix Completion(Beta) 思考/非思考模式均支持; FIM Completion(Beta) 仅非思考模式支持
  #   - "Responses API" 相关说法未在官方文档中找到依据, 可能是过时或非官方来源信息, 使用前建议自行核实
  #
  # reasoning_effort 映射 (官方 Thinking Mode 文档, 不区分 Pro/Flash, 统一规则):
  #   https://api-docs.deepseek.com/guides/thinking_mode
  #   low  → high   (映射, 非直通)
  #   medium → high (映射, 非直通)
  #   high → high   (直通, 思考模式默认档位)
  #   xhigh → max   (映射, 非直通)
  #   max  → max    (直通)
  #   ⚠️ 即 "low"/"medium" variant 在服务端实际等效于 "high", 并不会更快或更省
  #
  # ⚠️ 重要: 官方文档脚注明确说明, 对于 Claude Code、OpenCode 等复杂 agent 请求,
  #          reasoning_effort 会被服务端自动强制设为 max, 不论客户端传入什么值。
  #          这意味着下面给 opencode 配置的 light/medium/fast 等 variant
  #          在实际 opencode 会话中可能完全不生效, 一直按 max 档位计费与推理。
  #          如果需要控制成本/延迟, 目前没有已知的绕过方式, 需自行观察账单确认。
  #
  # 思考模式下 temperature/topP/presencePenalty/frequencyPenalty 均不生效
  # (设置不会报错, 但无效果) —— 仅在 "fast" (thinking.type = disabled) variant 下才实际生效
  #
  # deepseek-v4-flash 的 "-0731" checkpoint / public beta 说法未在官方 Change Log 中找到
  # 对应条目 (官方最新记录仍是 2026-04-24 发布 V4 Pro/Flash), 该信息来源存疑, release_date
  # 暂保留原值, 但不作为官方事实引用
  deepseek = {
    npm = "@ai-sdk/openai-compatible";
    name = "DeepSeek";
    env = [ "DEEPSEEK_API_KEY" ];
    options = {
      baseURL = "https://api.deepseek.com/v1";
      apiKey = "{env:DEEPSEEK_API_KEY}";
      timeout = 600000;
      headerTimeout = 600000;
      chunkTimeout = 60000;
    };

    models = {
      # =======================================================================
      # deepseek-v4-pro (1.6T 总参 / 49B 激活参数, MoE 架构)
      # 官方 status: preview → schema 不接受 "preview", 改为 "beta"
      # 不支持 Responses API (相关说法未经官方文档证实, 见上方 provider 级注释)
      # Chat Prefix Completion (Beta) 和 FIM Completion (Beta, 仅非思考模式) 均支持
      # =======================================================================
      "deepseek-v4-pro" = {
        name = "DeepSeek V4 PRO";
        family = "DeepSeek V4";
        release_date = "2026-04-24";
        status = "beta";
        reasoning = true;
        tool_call = true;
        attachment = false;
        experimental = false;

        cost = {
          input = 0.435;
          output = 0.87;
          cache_read = 0.003625;
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

        # low/medium 会被服务端映射为 high, xhigh 会被映射为 max —— 详见 provider 级注释
        variants = {
          "default" = { reasoningEffort = "high"; };
          "max-thinking" = { reasoningEffort = "max"; };
          "xhigh" = { reasoningEffort = "xhigh"; }; # 等效于 max, 保留仅为语义清晰
          "light" = { reasoningEffort = "low"; }; # ⚠️ 实际等效于 high, 并不会更快/更省
          "fast" = {
            thinking = { type = "disabled"; };
          };
        };
      };

      # =======================================================================
      # deepseek-v4-flash (284B 总参 / 13B 激活参数, MoE 架构)
      # release_date / "public beta" 说法未经官方 Change Log 证实, 谨慎参考
      # 定位: 快速/经济型, 推理能力接近 Pro
      # reasoning_effort 映射规则与 Pro 相同 (官方文档统一规则, 不区分模型) —— 见 provider 级注释
      # =======================================================================
      "deepseek-v4-flash" = {
        name = "DeepSeek V4 FLASH";
        family = "DeepSeek V4";
        release_date = "2026-07-31";
        status = "beta";
        reasoning = true;
        tool_call = true;
        attachment = false;
        experimental = false;

        cost = {
          input = 0.14;
          output = 0.28;
          cache_read = 0.0028;
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

        # low/medium 会被服务端映射为 high, xhigh 会被映射为 max —— 详见 provider 级注释
        variants = {
          "default" = { reasoningEffort = "high"; };
          "max-thinking" = { reasoningEffort = "max"; };
          "xhigh" = { reasoningEffort = "xhigh"; }; # 等效于 max, 保留仅为语义清晰
          "light" = { reasoningEffort = "low"; }; # ⚠️ 实际等效于 high, 并不会更快/更省
          "fast" = {
            thinking = { type = "disabled"; };
          };
        };
      };
    };
  };
}
