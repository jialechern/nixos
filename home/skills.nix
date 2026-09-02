{ pkgs, ... }:

let
  # ===========================================================================
  # 外部 skill 仓库 (每个 fetch 对应一类外部来源, 与下方 skills 属性集中的
  # 分组配合使用; 整组注释掉后对应 fetch 不会被求值, 也不会触发下载)
  # ---------------------------------------------------------------------------
  # anthropics/skills — Agent Skills 标准的源头仓库 (166K stars):
  #   - pdf / docx / xlsx / pptx: Claude 生产级文档处理四件套
  #     (阅读/生成/编辑/合并/OCR/填表等), 适合总结与文件管理场景
  #     注意: 这 4 个为 Proprietary (源码可用) 许可, 完整条款随各 skill 的
  #     LICENSE.txt 附带; 仅限个人使用, 勿重新分发
  #   - doc-coauthoring: 结构化文档协作编写工作流 (Apache-2.0)
  #   - skill-creator: 创建/评估/优化 skill 的元技能 (Apache-2.0)
  # ---------------------------------------------------------------------------
  # 更新方式: 替换 rev 后运行 nix flake check, 按 hash 不匹配报错填入新 hash
  anthropicSkills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "b29e7cf65e5cb78a5ac33d582270551bc74a14eb";
    hash = "sha256-RH2B03gj4kzw1j5LORezgUZPPu8mW+mWb+Kl2U7WUbY=";
  };

  # ===========================================================================
  # 需要部署的 skills, 按来源分组。属性 key 只是分组名 (可任意起), value 为:
  #   src   — 本组 skill 所在的目录, 目录下每个 <name>/SKILL.md 即一个 skill
  #   names — 本组要安装的 skill 名
  #
  # 启停 / 扩展:
  #   - 停用单个 skill:   注释掉 names 里对应的一行
  #   - 停用整个分组:     注释掉整个分组 (顶部对应 fetch 随之不被求值)
  #   - 新增本地 skill:   在 ./skills/ 下建 <name>/SKILL.md, 把名字加进 local.names
  #   - 新增外部来源:     先在顶部 fetch 对应仓库, 再照下列格式加一个分组
  # ===========================================================================
  skills = {
    # 仓库内自维护 (源码在 ./skills/<name>/SKILL.md)
    local = {
      src = ./skills;
      names = [
        "nixos-tooling" # 在 NixOS 上临时获取/运行 CLI 工具的标准流程
        "git-commit"    # 按 Conventional Commits 生成中文提交信息并提交
      ];
    };

    # anthropics/skills 官方仓库中选用的 skills
    anthropic = {
      src = "${anthropicSkills}/skills";
      names = [
        "skill-creator" # 创建/编辑/评估/优化 skill 的元技能
      ];
    };
  };

  # 将 skills 属性集展平为 [{ name, src }] 列表, 便于统一安装
  skillEntries = builtins.concatLists (builtins.map
    (group: builtins.map
      (name: { inherit name; src = "${group.src}/${name}"; })
      group.names)
    (builtins.attrValues skills));

  # 去除 skills 中可能重复的 skill
  names = builtins.map (e: e.name) skillEntries;
  uniqueNames = builtins.foldl'
    (acc: n: if builtins.elem n acc then acc else acc ++ [ n ])
    [ ]
    names;
  dupNames = builtins.filter
    (n: (builtins.length (builtins.filter (x: x == n) names)) > 1)
    uniqueNames;

  checked =
    if dupNames == [ ] then skillEntries
    else throw "home/skills.nix: 同名 skill 出现在多个分组: ${builtins.concatStringsSep ", " dupNames}";
in
{
  # 统一生成 home.file 条目, 均部署到 ~/.agents/skills/<name>
  # (pi / opencode / Claude Code 都会自动发现该目录, 一份源码多工具生效)
  home.file = builtins.listToAttrs (builtins.map (e: {
    name = ".agents/skills/${e.name}";
    value.source = e.src;
  }) checked);
}
