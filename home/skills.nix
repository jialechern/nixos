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

  # ---------------------------------------------------------------------------
  # firecrawl/skills — Firecrawl 官方 Agent Skills 仓库 (ISC 许可):
  #   - firecrawl-build-search: 集成 Firecrawl /search 的联网搜索 skill
  #     (搜索 → 结果排序 → 可选 hydrate 抓取正文), 适合"以查询为起点"的场景
  #   - firecrawl-build-scrape: 按 URL 抓取页面正文, search 的结果深化 (升级路径)
  #   - firecrawl-build-interact: 页面交互 (点击/表单), 复杂页面的升级路径
  #   - firecrawl-build: 主 skill, 汇总以上全部能力的入口
  #   - firecrawl-build-onboarding: build 系列的入门引导
  #     以上为引用闭环 (search ↔ scrape ↔ interact ↔ build, build → onboarding);
  #     未安装 firecrawl-research-index (独立, 无引用)
  #     注意: 需要 FIRECRAWL_API_KEY 环境变量
  # ---------------------------------------------------------------------------
  firecrawlSkills = pkgs.fetchFromGitHub {
    owner = "firecrawl";
    repo = "skills";
    rev = "7ad43730e76913c4d1e9f94bf6fa6f82e38fc12b";
    hash = "sha256-7wb6OEoeJnrljZ62F79psyHFCAWKMeWuBdpz/XzDSJw=";
  };
  firecrawlSkillNames = [
    "firecrawl-build"
    "firecrawl-build-search"
    "firecrawl-build-scrape"
    "firecrawl-build-interact"
    "firecrawl-build-onboarding"
  ];

  # ---------------------------------------------------------------------------
  # tavily-ai/skills — Tavily 官方 Agent Skills 仓库 (MIT 许可):
  #   - tavily-search: 通过 Tavily CLI (tvly) 的联网搜索 skill
  #     (LLM 优化结果, 支持时间范围/域名过滤/多深度), 适合"搜索/查资料/找最新信息"
  #   - tavily-cli: tvly CLI 安装与认证指南, search 的前置引用
  #   - tavily-extract: 从指定 URL 提取正文 (search 的深化路径)
  #   - tavily-research: 多来源综合研究 (search 的升级路径)
  #   - tavily-crawl: 整站抓取 (extract/research 的引用)
  #     以上为引用闭环 (search ↔ extract ↔ research ↔ cli, extract/research → crawl);
  #     未安装 tavily-map / tavily-dynamic-search / tavily-best-practices (独立, 无引用)
  #     注意: 运行时依赖 tvly CLI (见下方打包)
  # ---------------------------------------------------------------------------
  tavilySkills = pkgs.fetchFromGitHub {
    owner = "tavily-ai";
    repo = "skills";
    rev = "ea5e8201b0d3ed9c10b70b71187589bd761fe2d2";
    hash = "sha256-Y0eLc5afmz8IrFzB6f8WuTsEn6pmCzo8SMQ+OljIFKo=";
  };
  tavilySkillNames = [
    "tavily-search"
    "tavily-cli"
    "tavily-extract"
    "tavily-research"
    "tavily-crawl"
  ];

  # ---------------------------------------------------------------------------
  # upstash/context7 — Context7 官方仓库自带的 Agent Skills (Apache-2.0):
  #   - context7-cli: ctx7 CLI 全能指南 (查文档 / skills 管理 / MCP setup), 带 references
  #   - find-docs: 聚焦的文档查找工作流 (ctx7 CLI: library → docs 两步法)
  #   - context7-mcp: MCP 方式的文档查询 (resolve-library-id → query-docs),
  #     与 pi 的 @upstash/context7-pi 扩展工具一致
  #     注意: CLI 方式用 npx ctx7@latest 或全局安装; MCP 方式需 context7 MCP server;
  #     CONTEXT7_API_KEY 环境变量可提高速率限制 (sops 已配置)
  # ---------------------------------------------------------------------------
  context7Skills = pkgs.fetchFromGitHub {
    owner = "upstash";
    repo = "context7";
    rev = "594a73133e14631af8c915a1b4f2c8039c964fe1";
    hash = "sha256-Msvr7srpy+2HzxYKsPzo0hhzW7E1/ktTwdBEtuFMgRE=";
  };
  context7SkillNames = [
    "context7-cli"
    "find-docs"
    "context7-mcp"
  ];

  # ===========================================================================
  # skill 运行时依赖 (打包与 skill 一起维护, 职责跟随 skill 归属)
  # ---------------------------------------------------------------------------
  # tvly — Tavily CLI, tavily-search skill 的运行时依赖
  # 上游: github.com/tavily-ai/tavily-cli (MIT) + 依赖 tavily-python (MIT)
  # nixpkgs 未收录这两个包, 故从源码声明式打包 (rev 锁定, 更新时替换 rev + hash)
  # 认证方式 (按优先级): TAVILY_API_KEY 环境变量 > ~/.tavily/config.json (tvly login) > MCP OAuth token
  # ---------------------------------------------------------------------------
  # Tavily Python SDK, tavily-cli 的运行时依赖
  tavilyPython = pkgs.python3Packages.buildPythonPackage {
    pname = "tavily-python";
    version = "0.7.27";
    src = pkgs.fetchFromGitHub {
      owner = "tavily-ai";
      repo = "tavily-python";
      rev = "de924695765d5cf28bd1975c1cfca0cd07cd7005";
      hash = "sha256-dCegpLNWjFbuBb9bKGGZS3NKy4R92l/X0Cjz9ToQZHU=";
    };
    format = "setuptools";
    propagatedBuildInputs = with pkgs.python3Packages; [
      requests
      tiktoken
      httpx
    ];
    doCheck = false; # 上游无本地可跑的测试
  };

  # Tavily CLI, 提供 tvly 命令
  tavilyCli = pkgs.python3Packages.buildPythonApplication {
    pname = "tavily-cli";
    version = "0.1.6";
    src = pkgs.fetchFromGitHub {
      owner = "tavily-ai";
      repo = "tavily-cli";
      rev = "577c8c9ac9d644eb2affcc8b99d03254ab123e71";
      hash = "sha256-wL7Ak8fKUxttBgzAadbq759IgKx9omHTaJPxn1klT4g=";
    };
    format = "pyproject";
    build-system = [ pkgs.python3Packages.hatchling ];
    propagatedBuildInputs = with pkgs.python3Packages; [
      tavilyPython
      click
      rich
      httpx
      requests
      urllib3
      certifi
      psutil
    ];
    doCheck = false; # 上游无本地可跑的测试
  };

  # ===========================================================================
  # 统一生成 home.file 条目, 均部署到 ~/.agents/skills/<name>
  # (pi / opencode / Claude Code 都会自动发现该目录, 一份源码多工具生效)
  # ===========================================================================
  skills = localSkills ++ anthropicSkillNames ++ firecrawlSkillNames ++ tavilySkillNames ++ context7SkillNames;

  srcFor = name:
    if builtins.elem name localSkills then
      ./skills/${name}
    else if builtins.elem name firecrawlSkillNames then
      "${firecrawlSkills}/skills/${name}"
    else if builtins.elem name tavilySkillNames then
      "${tavilySkills}/skills/${name}"
    else if builtins.elem name context7SkillNames then
      "${context7Skills}/skills/${name}"
    else
      "${anthropicSkills}/skills/${name}";
in
{
  home.file = builtins.listToAttrs (map (name: {
    name = ".agents/skills/${name}";
    value.source = srcFor name;
  }) skills);

  # tavily-search skill 的运行时依赖 (tvly CLI)
  home.packages = [ tavilyCli ];
}
