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
            apiKey = "{env:ARK_API_KEY}";
        };

        models = {
            "doubao-seed-code-preview-251028" = {
                # 在 `/models` 列表里显示的名称
                name = "Doubao Seed Code Preview";

                # OpenCode 需要知道模型可接受多少上下文
                limit = {
                    # 模型接受的最大输入 tokens
                    context = 224000;

                    # 模型接受的最大输出 tokens (火山方舟官方写明: max_tokens 最大 32k (不含思考内容))
                    output = 32000;
                };
            };
            
            "deepseek-v3-2-251201" = {
                name = "DeepSeek V3.2";
                limit = {
                    context = 128000;
                    output = 8000;
                };
            };

            "deepseek-r1-250528" = {
                name = "DeepSeek R1";
                limit = {
                    context = 128000;
                    output = 64000;
                };
            };

            "doubao-seed-1-6-flash-250828" = {
                name = "Doubao Seed 1.6 Flash";
            };

            "doubao-seed-1-8-251228" = {
                name = "Doubao Seed 1.8";
            };

            "doubao-seed-translation-250915" = {
                name = "Doubao Seed Translation";
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
            "deepseek-chat" = {
                name = "DeepSeek Chat";

                limit = {
                    context = 128000;
                    output = 8000;
                };
            };

            "deepseek-reasoner" = {
                name = "DeepSeek Reasoner";

                limit = {
                    context = 128000;
                    output = 64000;
                };
            };
        };
    };
}
