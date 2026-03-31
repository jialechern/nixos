{ config, inputs, pkgs, username, lib, ... }:

{
  # 导入 sops-nix 模块
    imports = [
        inputs.sops-nix.homeManagerModules.sops
    ];

  # 配置 sops-nix
    sops = {
        # 告知 sops-nix 的 age 私钥位置 (用于解密)
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt"; 

        # 默认的加密文件路径 (可选, 如果有多个文件, 可以在 secrets 中单独指定)
        defaultSopsFile = ./secrets/default.yaml;

        # 声明要解密的秘密变量
        secrets = {
            # 不把它放到默认的 `/run/user/...` 目录
            # 而是直接映射到 SSH 默认读取的路径
            "id_ed25519" = {
                sopsFile = ./secrets/ssh_keys/git.yaml;
                path = "${config.home.homeDirectory}/.ssh/id_ed25519";
                mode = "0600";
            };

            "ark" = {
                sopsFile = ./secrets/ai_api_keys/module_api_keys.yaml;
            };

            "deepseek" = {
                sopsFile = ./secrets/ai_api_keys/module_api_keys.yaml;
            };

            "baidu_map" = {
                sopsFile = ./secrets/ai_api_keys/mcp_api_keys.yaml;
            };

            "context7" = {
                sopsFile = ./secrets/ai_api_keys/mcp_api_keys.yaml;
            };

            "firecrawl" = {
                sopsFile = ./secrets/ai_api_keys/mcp_api_keys.yaml;
            };

            "tavily" = {
                sopsFile = ./secrets/ai_api_keys/mcp_api_keys.yaml;
            };

            # 预留给未来的私密数据
            # "secret_data" = { ... };
        };

        templates = {
            "aider-secrets.env" = {
                path = "${config.home.homeDirectory}/.config/aider/secrets.env";
                content = ''
                    # --- DeepSeek 开放平台 ---
                    DEEPSEEK_API_KEY=${config.sops.placeholder.deepseek}

                    # --- 火山方舟开放平台 ---
                    OPENAI_API_KEY=${config.sops.placeholder.ark}
                    OPENAI_API_BASE=https://ark.cn-beijing.volces.com/api/v3
                '';
                mode = "0600";
            };

            "opencode-secrets.env" = {
                path = "${config.home.homeDirectory}/.config/opencode/secrets.env";
                content = ''
                    # --- 火山方舟 ---
                    ARK_API_KEY=${config.sops.placeholder.ark}
                    # --- DeepSeek 开放平台 ---
                    DEEPSEEK_API_KEY=${config.sops.placeholder.deepseek}
                    # --- MCP ---
                    CONTEXT7_API_KEY=${config.sops.placeholder.context7}
                    FIRECRAWL_API_KEY=${config.sops.placeholder.firecrawl}
                    TAVILY_API_KEY=${config.sops.placeholder.tavily}
                    BAIDU_MAP_API_KEY=${config.sops.placeholder.baidu_map}
                    BAIDU_MAPS_API_KEY=${config.sops.placeholder.baidu_map}
                '';
                mode = "0600";
            };
        };
    };

    # 确保安装 sops 工具, 方便以后日常修改密码
    home.packages = with pkgs; [
        sops
        age
    ];
}
