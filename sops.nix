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

      # Gitee 的完整访问令牌, 用于访问私有仓库
      "gitee_full_token" = {
        sopsFile = ./secrets/git_tokens/gitee.yaml;
      };

      # GitHub 只读令牌, 用于拉取私有仓库
      "github_pull_only_token" = {
        sopsFile = ./secrets/git_tokens/github.yaml;
      };
    };

    templates = {
      "opencode-secrets.env" = {
        path = "${config.home.homeDirectory}/.config/opencode/secrets.env";
        content = ''
          # --- 火山方舟 ---
          VOLCANO_ARK_API_KEY=${config.sops.placeholder.ark}
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

      "netrc" = {
        path = "${config.home.homeDirectory}/.netrc";
        content = ''
          machine github.com
          login oauth2
          password ${config.sops.placeholder."github_pull_only_token"}
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
