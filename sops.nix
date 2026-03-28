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
    defaultSopsFile = ./secrets/ssh_keys/git.yaml;

    # 声明要解密的秘密变量
    secrets = {
      # 不把它放到默认的 `/run/user/...` 目录
      # 而是直接映射到 SSH 默认读取的路径
      "id_ed25519" = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
        mode = "0600";
      };
      
      # 预留给未来的私密数据
      # "secret_data" = { ... };
    };
  };

  # 确保安装 sops 工具, 方便以后日常修改密码
  home.packages = with pkgs; [
    sops
    age
  ];
}
