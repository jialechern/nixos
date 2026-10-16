# extension groups 定义 —— 本文件的内容就是 ~/.pi/agent/extension-groups.json
#
# 部署: pi.nix 的 home.file.".pi/agent/extension-groups.json" 用 builtins.toJSON 转换
#   本文件后软链到该路径 (声明式只读软链: 改组请改这里后 rebuild)。
# 消费方: pi.nix 部署的用户级扩展 extensions-manager.ts —— 其 /exts 命令在 pi 会话内
#   把这些组装配到当前项目的 .pi/settings.json:
#     装配基础集合  /exts add-group init     (幂等, 已装的跳过)
#     装配编码集合  /exts add-group coding
#     卸载全部      /exts clean             (带确认; -y 跳过)
#     查看清单      /exts list              (含组标注; 组名 Tab 补全)
#   装配后扩展自动 reload 生效, 无需重启 pi。
# 注: 写操作要求项目已被信任 (会话内用 /trust 授予), 未信任时 /exts 会弹确认,
#   或加 -y 直接写入 (不保存信任决定); list 始终可用。
# 设计: 这些包不进全局 settings.packages, 因此未装配它们的项目是零启动成本;
#   某个项目想用不同的组内容时, 可在该项目 .pi/extension-groups.json 定义同名组整体覆盖。
{
  # 基础集合: 通用能力, 任何项目都可能想要
  init = {
    description = "基础集合: 通用能力, 任何项目都可能想要 (待办 / 子代理 / 网页访问)";
    packages = [
      # 待办清单 (MIT, juicesharp): todo 工具 + /todos 命令 + 编辑器上方实时面板
      # 注: 面板折叠键 (ctrl+shift+f) 被 kitty 拦截, 目前实际不可用;
      # 换键与 pi 侧抢键告警的说明见 pi.nix 的 rpiv-todo 配置注释。
      "npm:@juicesharp/rpiv-todo"
      # 子代理: 把任务委托给专注的子会话
      "npm:pi-subagents"
      # 网页访问: 搜索 / 抓取 / GitHub 克隆 / PDF / 视频理解
      # 配置见同目录 web-search.nix (部署为 ~/.pi/agent/web-search.json)
      "npm:pi-web-access"
    ];
  };
  # 编码集合: 与基础集合正交, 只含编码相关。
  # add-group 是幂等追加, 各组叠加即得并集: 日常项目只装 init 保持轻量,
  # 编码项目再叠加 coding, 主动用启动耗时换功能。
  # 需要继续细化时可再加一组 (如 audit → 审计集合)。
  coding = {
    description = "编码集合: 实时代码反馈 LSP 诊断 / linter / autofix (与基础正交)";
    packages = [
      # 实时代码反馈 (LSP 诊断 / linter / autofix)
      "npm:pi-lens"
      # 简单代码审查
      "npm:pi-simplify"
    ];
  };
}
