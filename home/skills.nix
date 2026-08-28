{ pkgs, ... }:

let
  # ===========================================================================
  # 仓库内自维护 skills (新增: 在 ./skills/ 下建 <name>/SKILL.md 并加入此列表)
  # ===========================================================================
  localSkills = [ "nixos-tooling" "git-commit" ];

  # ===========================================================================
  # 外部知名仓库 skills
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
  anthropicSkillNames = [
    "pdf"
    "docx"
    "xlsx"
    "pptx"
    "doc-coauthoring"
    "skill-creator"
  ];

  # ===========================================================================
  # 统一生成 home.file 条目, 均部署到 ~/.agents/skills/<name>
  # (pi / opencode / Claude Code 都会自动发现该目录, 一份源码多工具生效)
  # ===========================================================================
  skills = localSkills ++ anthropicSkillNames;

  srcFor = name:
    if builtins.elem name localSkills then
      ./skills/${name}
    else
      "${anthropicSkills}/skills/${name}";
in
{
  home.file = builtins.listToAttrs (map (name: {
    name = ".agents/skills/${name}";
    value.source = srcFor name;
  }) skills);
}
