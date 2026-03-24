{ config, pkgs, ... }:

{
    programs.zoxide = {
        enable = true;

        # 开启 Shell 支持
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;

        # 其它 init 选项
        options = [
            # 使用 cd 作为更换路径的命令
            "--cmd cd"
            # 仅在真正切换路径时将路径计入数据库
            "--hook pwd"
        ]; 
    };
}
