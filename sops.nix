{ config, inputs, pkgs, ... }:

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

      "deepseek_api_key" = {
        sopsFile = ./secrets/ai_api_keys/module_api_keys.yaml;
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

      # GitHub 只读令牌, 用于拉取私有仓库
      "github_pull_only_token" = {
        sopsFile = ./secrets/git_tokens/github.yaml;
      };
    };

    templates = {
      "pi-secrets.env" = {
        path = "${config.home.homeDirectory}/.config/pi/secrets.env";
        content = ''
          # --- DeepSeek 官方 API ---
          DEEPSEEK_API_KEY=${config.sops.placeholder.deepseek_api_key}
          # --- pi-web-access 联网搜索 ---
          TAVILY_API_KEY=${config.sops.placeholder.tavily}
          FIRECRAWL_API_KEY=${config.sops.placeholder.firecrawl}
          # --- context7 文档查询 ---
          CONTEXT7_API_KEY=${config.sops.placeholder.context7}
          # --- pi-web-access GitHub 能力 (gh CLI 认证) ---
          # 复用 .netrc 同源的只读令牌; 实际可访问范围取决于该 token 自身权限
          GH_TOKEN=${config.sops.placeholder."github_pull_only_token"}
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
