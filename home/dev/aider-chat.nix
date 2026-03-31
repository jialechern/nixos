{ config, pkgs, ... }:

{
    # =========================================================
    # 依赖程序
    # =========================================================
    home.packages = with pkgs; [
        portaudio                # /voice 语音输入需要
        playwright-driver.browsers # /web 的 Playwright 浏览器, NixOS 下推荐这样提供
    ];


    # =========================================================
    # Playwright 配置
    # =========================================================
    home.sessionVariables = {
        # 让 Playwright 直接使用 nixpkgs 提供的浏览器包
        PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";

        # 避免 Playwright 在 NixOS 上做宿主依赖检查时报错
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
    };

    # =========================================================
    # aider 核心配置
    # =========================================================
    programs.aider-chat = {
        enable = true;

        # 使用满配软件包
        package = pkgs.aider-chat-full;

        settings = {
            # =========================================================
            # 模型与核心逻辑
            # =========================================================

            # 主模型: 负责主要对话、规划和代码修改
            # 这里先保留的自定义模型名; 如果后面 Aider 仍提示不认识,
            # 就把它补进 model-metadata/model-settings 文件里
            model = "openai/doubao-seed-code-preview-251028";

            # 开启 Architect 模式:
            # 让主模型先负责构思方案, 再由编辑模型落地修改
            architect = true;

            # Architect 模式下是否自动接受架构师建议
            # 为了稳妥起见, 这里先关掉, 避免 AI 过于激进
            "auto-accept-architect" = false;

            # # 如果后面想更精细地指定编辑模型
            # # 可以在这里再补 editor-model / editor-edit-format
            # "editor-model" = "xxx";
            # "editor-edit-format" = "diff";

            # =========================================================
            # 安全与环境变量
            # =========================================================

            # 从外部文件读取 API Key 和其它环境变量
            # 避免把敏感信息写进 /nix/store
            "env-file" = "${config.xdg.configHome}/aider/secrets.env";

            # 自定义模型如果 Aider 不认识
            # 就把上下文窗口和费用写进这个文件, 能消掉那条 warning
            # 文件位置可以放在家目录 / git repo 根目录 / 当前目录
            # 这里统一指向 ~/.config/aider 下的文件, 便于管理
            "model-metadata-file" = "${config.xdg.configHome}/aider/model.metadata.json";

            # 如果这个模型需要特殊的编辑格式、弱模型、是否启用 repo map 等
            # 可以在这个文件里覆盖
            "model-settings-file" = "${config.xdg.configHome}/aider/model.settings.yml";

            # =========================================================
            # 界面与终端体验
            # =========================================================

            # 暗色终端配色
            "dark-mode" = true;

            # 彩色、较美观的输出
            pretty = true;

            # 流式输出
            stream = true;

            # 终端输入增强: 历史、补全等
            "fancy-input" = true;

            # 支持多行输入, 适合写较长提示词
            multiline = true;

            # 自动识别 URL, 并在需要时提示加入上下文
            "detect-urls" = true;

            # 自动提示 shell 命令建议
            "suggest-shell-commands" = true;

            # 默认编辑器: Neovim
            editor = "nvim";

            # =========================================================
            # Git 深度集成
            # =========================================================

            # Aider 的核心工作流就是围绕 git 仓库
            git = true;

            # 让 Aider 自动把 .aider* 写入 .gitignore
            gitignore = true;

            # 自动提交 AI 改动
            "auto-commits" = true;

            # 即使当前目录有未提交内容, 也允许继续工作
            "dirty-commits" = true;

            # 不把作者信息强行写进 commit 历史
            "attribute-author" = false;
            "attribute-committer" = false;
            "attribute-commit-message-author" = false;
            "attribute-commit-message-committer" = false;
            "attribute-co-authored-by" = false;

            # =========================================================
            # 代码地图与上下文
            # =========================================================

            # Repo map 的建议 token 数
            # Aider 官方对 2048 以内更友好; 4096 会更容易被提醒"不推荐"
            "map-tokens" = 2048;

            # 缓存提示词，降低重复请求成本
            "cache-prompts" = true;

            # 检查模型是否接受 reasoning/thinking 等设置
            # 对自定义模型更稳妥。
            "check-model-accepts-settings" = true;

            # 保留模型警告:
            # 这样如果以后模型名拼错、参数不兼容，还能看到提示
            # 如果只是想彻底静音, 也可以改成 false
            "show-model-warnings" = true;

            # =========================================================
            # 语言偏好
            # =========================================================

            # 聊天默认中文
            "chat-language" = "zh";

            # 提交信息默认中文
            "commit-language" = "zh";

            # =========================================================
            # 测试与自动化
            # =========================================================

            # 这里先不全局设置 test-cmd
            # 更推荐在具体项目目录里写 `.aider.conf.yml` 覆盖:
            #
            #   test-cmd: cargo test
            #   auto-test: true
            #
            # 原因是不同项目的测试命令差异很大, 放到全局配置里容易不合适
            # Aider 官方说明 auto-test 默认是 false, test-cmd 默认也是空的
            #
            # "test-cmd" = [ ];
            #
            # Aider 会按"家目录 → git repo 根目录 → 当前目录"顺序加载配置
            "auto-test" = false;

            # =========================================================
            # 其它常用项
            # =========================================================

            # 如果想让 Aider 更积极地提示, 可保持 true
            # 默认也是 true, 这里显式写出来更直观
            "git-commit-verify" = true;

            # 不要把 .gitignore 里的文件自动纳入编辑范围
            # 这个默认就是 false, 显式写出来便于你以后回看
            "add-gitignore-files" = false;

            # 只在当前子树内工作; 默认 false
            "subtree-only" = false;

            # 依赖已通过 nixpkgs 提供, 这里保留默认可用状态
            "disable-playwright" = false;
        };
    };
    
    imports = (builtins.filter builtins.pathExists [
        # 模型配置
        ./aider-chat/model.nix
    ]);

  # --- shell 别名 ---
    programs.bash.shellAliases = {
        ai = "aider";
    };

    programs.fish.shellAliases = {
        ai = "aider";
    };

    programs.zsh.shellAliases = {
        ai = "aider";
    };
}
