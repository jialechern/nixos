{
  config,
  inputs,
  pkgs,
  ...
}:

{
  # 导入 sops-nix 模块
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  # 配置 sops-nix
  sops = {
    # 告知 sops-nix 的 age 私钥位置 (用于解密)
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # 注: 不设 defaultSopsFile —— 每个 secret 都显式写了 sopsFile; 默认文件
    # (secrets/default.yaml) 只是个空文件, 已删除

    # 声明要解密的秘密变量
    secrets = {
      # 不放到 sops-nix 的默认路径 (~/.config/sops-nix/secrets/<name>)
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
      # 注: 不再生成 ~/.config/pi/secrets.env —— pi 的包装脚本 (home/dev/pi.nix)
      # 直接读上面 secrets 声明的文件, 少一份明文落盘 (旧的 env 文件可手动删除)
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
