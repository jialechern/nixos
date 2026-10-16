# pi-zentui 配置数据 —— 本文件的内容就是 ~/.pi/agent/zentui.json
#
# 部署: pi.nix 的 home.file.".pi/agent/zentui.json" 用 builtins.toJSON 转换本文件
#   后软链到该路径。软链是**只读**的: /zentui 面板保存会失败 (面板仍可打开/预览),
#   取舍与"临时试"流程写在 pi.nix 的部署条目上; 改配置请改这里后 rebuild。
# 包来源: pi.nix 的 settings.packages 里的 npm:pi-zentui (不锁版本)。
#
# 出处与依据:
#   * 官方手册随包发布: ~/.pi/agent/npm/node_modules/pi-zentui/docs/
#       configuration.md (全部键/取值/默认值) · footer-format.md (模板变量) ·
#       tool-display.md (工具渲染预设)
#   * 取值经过: GitHub 代码搜索取到的 20 份社区 zentui.json 统计 + 官方 4 个预设。
#       社区主流 = opencode 家族编辑器 (11/20)、starship 页脚 (15/20)、theme 色源、
#       adaptive 边框、dot 分隔、text+gauge 上下文、tree 思考、star-bloom 转轮;
#       toolDisplay 是 0.31 新组件, 20 份里没人配过, 这里按文档取中间档。
#   * 2026-10-16 在本机 pi 1.3.0 上按"热调试 → 回写声明"流程逐项实测确认。
#
# 版本前提与风险:
#   * 整套需 pi >= 1.0.0。
#   * thinkingSteps 是官方标注的实验项 (基于私有 AssistantMessageComponent 补丁,
#     文档原话 "Private APIs may break after any Pi update"); 失败会自动回退原生
#     思考显示 (fail-open)。它把每个思考段落压成一行并用 … 裁剪 —— 想看完整思考
#     链就把它置 false (或删掉整段, 该项默认即关)。
#   * toolDisplay 依赖 pi 公开的 registerToolRenderer (pi 1.0.3 起; OMP 侧没有),
#     宿主不支持时保持原生渲染。
#   * 版本漂移: 包不锁版本, 升级 pi 或 zentui 后若某组件失效, 先用 pi.nix 里写的
#     "临时试"流程在本地验证, 再决定改这里还是给 npm:pi-zentui 钉版本。
{
  # 图标: kitty 用 JetBrainsMono Nerd Font, 显式钉 nerd, 不依赖 auto 的终端探测
  icons.mode = "nerd";

  components = {
    # --- 编辑器: opencode 家族 (模型元数据嵌在边框) 的复制友好变体 ---
    # 选择竖线不进复制内容 (配合 pi 的 OSC 52 复制), 保留下方一行元数据
    editor = {
      enabled = true;
      style = "opencode-copy-friendly";
      colorSource = "theme"; # 取 Pi 主题色 (本机 theme = system, 由终端调色板生成)
      borderColorMode = "adaptive"; # 边框随思考档位变色
      modelLabel = "name"; # 显示名而非模型 id
      viewportIndicators = true; # 内容被截断时显示视口计数

      styles.opencode-copy-friendly = {
        # 左区: 模型 · provider · 思考档位; 右区($fill 之后): 上下文用量 · 累计 token
        # $join_sep 只在相邻字段非空时插入 " · ", 空字段不留孤立分隔符
        metadataFormat = "$model$join_sep$provider$join_sep$thinking$fill$context$join_sep$tokens";
        completionMenu = "palette"; # 透明补全菜单 (保留原生行与选中色)
      };
    };

    # --- 用户消息: 与编辑器同一家族 (留横向边框, 去掉会被抄走的竖线) ---
    userMessages = {
      enabled = true;
      style = "framed-copy-friendly";
    };

    # --- Working 行: 接管 Pi 的整行工作状态, 嵌入编辑器上边框 (省一行) ---
    workingLine = {
      enabled = true;
      placement = "border";
      spinner = "star-bloom";
      textAnimation = "classic";
      turnSummary = true; # 结算后追加 "Turn took … · ↑in ↓out · N tok/s avg"
      segments = {
        tool = true; # 当前工具名
        elapsed = true; # 本回合耗时
        thought = true; # 累计思考时长
        tokens = true; # 本回合 token
        tokenRate = true; # 实时速率 (估计值带 ~)
      };
    };

    # --- 工具显示: balanced 预设, MCP 结果单独设为 preview ---
    toolDisplay = {
      enabled = true;
      style = "balanced"; # read 摘要 / grep 计数 / bash 展开
      mcpOutputMode = "preview"; # MCP 结果折叠时只留 "Ctrl+O to expand"
      diffViewMode = "auto"; # edit/write 的 diff: 够宽用 split, 窄则退 unified
      diffIndicatorMode = "bars";
      showTruncationHints = true;
    };

    # --- 思考显示 (实验项, 见文件头风险说明): tree = 每个思考段落渲染成树节点 ---
    thinkingSteps = {
      enabled = true;
      mode = "tree";
    };

    # --- 页脚: Starship 风格状态行 (native | starship | hidden) ---
    footer = {
      style = "starship";
      colorSource = "theme";
      modelLabel = "name";
      styles.starship = {
        responsive = true; # 放不下先重排, 再退到 compactFormat
        compactMaxLines = 2;
        separator = "dot";
        contextStyle = "text+gauge"; # 文本 + 方块仪表
        pathDisplay = {
          # 仓库内显示相对路径 (仓库根显示 .), 找不到仓库时退回完整路径
          mode = "repository";
          depth = 0; # 0 = 不限层数
        };
        # 段式布局: format 留空 ⇒ 由下面的开关决定宽版布局
        # (一旦写了非空 format, 这些开关对宽版即失效)
        segments = {
          cwd = true;
          sessionName = true;
          gitBranch = true;
          gitStatus = true;
          gitMetrics = true; # 未提交改动行数 (仅非零时显示)
          runtime = true; # 项目检测到的语言/运行时
          context = true;
          tokens = true;
          cost = true;
          sessionDuration = true;
          # 有意关闭: username / time / os / packageVersion
          #           gitCommit (仅 detached HEAD 有意义)
          #           modelInfo (编辑器边框已显示模型名, 避免重复)
        };
        extensionStatuses.defaultPlacement = "right"; # pi-lens 等状态落在右区
      };
    };

    # --- 选择器边框: /resume、模型选择等列表用 zentui 配色描边 ---
    selectorBorders.enabled = true;
  };
}
