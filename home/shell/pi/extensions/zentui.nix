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
#   * 2026-10-16 在本机 pi 1.3.0 上按"热调试 → 回写声明"流程逐项实测确认;
#     2026-10-28 按 zentui 0.33.0 的 config.ts 默认值裁剪过一轮。
#
# 书写原则: **只写与默认值不同的键**。与默认相同的项一律不写, 免得配置里出现
#   一堆"其实什么都不改"的行 —— 各块注释里说"默认即 X, 不写"的就是这些省略项。
#   默认值出处: docs/configuration.md 的默认值列, 或 extensions/zentui/config.ts
#   的 defaultConfig / defaultComponents。代价是省略项会跟着上游默认一起变 (上游
#   改默认时本文件行为随之变), 这属于有意共享默认, 不是漏写。
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
    # enabled / viewportIndicators / completionMenu=palette 都与默认相同, 不写;
    # 下列四项即全部覆盖项 (默认 style=opencode / colorSource=terminal /
    # borderColorMode=static / modelLabel=id)。
    editor = {
      style = "opencode-copy-friendly";
      colorSource = "theme"; # 取 Pi 主题色 (本机 theme = system, 由终端调色板生成)
      borderColorMode = "adaptive"; # 边框随思考档位变色
      modelLabel = "name"; # 显示名而非模型 id

      styles.opencode-copy-friendly = {
        # 左区: 模型 · provider · 思考档位; 右区($fill 之后): 上下文用量 · 累计 token
        # $join_sep 只在相邻字段非空时插入 " · ", 空字段不留孤立分隔符
        # (默认格式是 "$model  $provider(  $thinking)(  $fast_mode)(  $codex_quota)")
        metadataFormat = "$model$join_sep$provider$join_sep$thinking$fill$context$join_sep$tokens";
      };
    };

    # --- 用户消息: 与编辑器同一家族 (留横向边框, 去掉会被抄走的竖线) ---
    # 只有 style 与默认 framed 不同; enabled 默认即 true, 不写。
    userMessages.style = "framed-copy-friendly";

    # --- Working 行: 接管 Pi 的整行工作状态, 嵌入编辑器上边框 (省一行) ---
    # 该组件 0.31 起的默认值就已是本文件想要的形态 (enabled、placement=border 省一行、
    # spinner=star-bloom、textAnimation=classic、turnSummary 结算行、segments 五项全开),
    # 故一律不写, 只留下面这一条颜色覆盖。
    workingLine = {
      # 只压暗结算行本身: 不写时继承 Working 的 high 档, 在转录里偏亮抢眼;
      # 只影响**新**结算行 (格式与颜色随条目快照, 改这里不重写历史记录)
      colors.turnSummary = "bright-black";
    };

    # --- 工具显示: balanced 预设 + MCP 结果单独设为 preview ---
    # 默认关闭且 style=opencode (read/grep/MCP 全隐藏), 所以 enabled 与 style 必须写。
    toolDisplay = {
      enabled = true;
      style = "balanced"; # read 摘要 / grep 计数 / bash 展开
      mcpOutputMode = "preview"; # 覆盖 balanced 预设的 summary: 只留 "Ctrl+O to expand"
      showTruncationHints = true; # 默认 false
    };

    # --- 思考显示 (实验项, 见文件头风险说明): tree = 每个思考段落渲染成树节点 ---
    # 默认 mode 即 tree、仅 enabled 默认关闭, 故只写开关。
    thinkingSteps.enabled = true;

    # --- 页脚: Starship 风格状态行 ---
    # style 默认即 starship (native | starship | hidden 三选一), 故不写;
    # 下列两项的默认分别是 terminal / id。
    footer = {
      colorSource = "theme";
      modelLabel = "name";
      styles.starship = {
        separator = "dot"; # 默认 pipe
        contextStyle = "text+gauge"; # 默认 text; 文本 + 方块仪表
        # 仓库内显示相对路径 (仓库根显示 .), 找不到仓库时退回完整路径;
        # 默认 mode=basename。depth 默认 0 (不限层数)。
        pathDisplay.mode = "repository";
        # 段式布局: format 留空 ⇒ 由 segments 开关决定宽版布局
        # (一旦写了非空 format, 这些开关对宽版即失效)
        # 只列与默认不同的两项; 其余段保持默认 (modelInfo 不写: 编辑器边框已显示
        # 模型名; gitCommit 仅 detached HEAD 有意义)。
        segments = {
          gitMetrics = true; # 未提交改动行数 (默认关, 仅非零时显示)
          sessionDuration = true; # 会话时长 (默认关)
        };
        # extensionStatuses.defaultPlacement 默认即 right (pi-lens 等状态落右区)
      };
    };

    # 选择器边框 (/resume、模型选择等列表用 zentui 配色描边) 默认即
    # enabled + style=zentui + colorSource=terminal, 无一处需要覆盖。
  };
}
