{ config, lib, pkgs, username, ... }:

let
  # 自定义模板文件的路径(若不需要自定义模板, 可忽略)
  # 模板文件来源: https://github.com/jgm/pandoc-templates
  # latexTemplate = ./templates/default.latex;
  # htmlTemplate  = ./templates/default.html;

  # 自定义 CSL 引用样式文件的路径(若不需要自定义样式, 可忽略)
  # CSL 样式库: https://www.zotero.org/styles
  # chicagoCsl = ./styles/chicago-author-date.csl;
  # ieeeCsl    = ./styles/ieee.csl;
in
{
  # =========================================================================
  # programs.pandoc — Home Manager Pandoc 模块配置
  # =========================================================================

  programs.pandoc = {
    # -------------------------------------------------------------------
    # 1. programs.pandoc.enable (布尔值, 默认 false)
    #   是否启用 pandoc 配置. 
    # -------------------------------------------------------------------
    enable = true;

    # -------------------------------------------------------------------
    # 2. programs.pandoc.package (package 类型, 默认 pkgs.pandoc)
    #   指定要使用的 pandoc 软件包. 可以在此处注入额外的过滤器或交叉引用
    #   工具, 例如 pandoc-crossref、pandoc-include 等
    #   常见组合示例：
    #     pkgs.pandoc
    #     pkgs.pandoc.override { extraPandocInputs = with pkgs; [ pandoc-crossref pandoc-include ]; }
    # -------------------------------------------------------------------
    package = pkgs.pandoc;

    # -------------------------------------------------------------------
    # 3. programs.pandoc.defaults (JSON 值, 默认 {})
    #   pandoc 的默认选项, 将被转换为 JSON 并写入一个 defaults 文件.
    #   pandoc 启动时会自动通过 --defaults 参数加载该文件, 因此所有此处
    #   设置的选项都会成为 pandoc 的全局默认值.
    # -------------------------------------------------------------------
    defaults = {
      # --- 元数据设置 ---
      # metadata: 设置文档的默认元数据字段(作者、标题、日期等),
      #           可在命令行中通过 --metadata 覆盖.
      metadata = {
        author = "${username}";      # 默认作者名
        # title = "";              # 默认标题(留空表示由源文件指定)
        # date = "";               # 默认日期(留空表示由源文件指定)
        lang = "zh-CN";            # 默认语言(影响引号样式、连字符等)
      };

      # --- PDF 引擎 ---
      # pdf-engine: 指定生成 PDF 时使用的引擎.
      #   常用选项: xelatex, lualatex, pdflatex, wkhtmltopdf, weasyprint,
      #            prince, context, pdfroff, typst
      #   中文文档推荐使用 xelatex(通过 texlive 提供).
      pdf-engine = "xelatex";

      # --- 引用处理 ---
      # citeproc: 是否启用 pandoc-citeproc 进行文献引用处理.
      #           如果文档中包含参考文献(如 BibTeX/BibLaTeX),
      #           启用此选项会自动处理引用和生成参考文献列表.
      citeproc = true;

      # --- 输入/输出格式 ---
      # from: 指定默认输入格式. 留空时 pandoc 会自动检测.
      #   常用格式: markdown, markdown+smart, gfm, org, latex, html,
      #            docx, epub, rst, textile, typst
      # from = "markdown+smart";

      # to: 指定默认输出格式.
      #   常用格式：pdf, latex, html, html5, docx, epub, markdown,
      #            plain, revealjs, beamer, pptx, typst
      # to = "pdf";

      # --- 文档结构 ---
      # standalone: 是否生成独立的完整文档(包含头部和脚部).
      #             生成 PDF 或 HTML 时通常需要设为 true.
      standalone = true;

      # table-of-contents: 是否自动生成目录.
      table-of-contents = true;

      # toc-depth: 目录中包含的最大标题深度, 默认 3.
      toc-depth = 3;

      # number-sections: 是否对章节进行自动编号.
      number-sections = true;

      # shift-heading-level-by: 将标题级别整体偏移(正数升高, 负数降低).
      #   例如设为 -1 则原 # 变为标题(非章节), 原 ## 变为 #.
      # shift-heading-level-by = -1;

      # --- 高亮样式 ---
      # highlight-style: 代码块语法高亮样式.
      #   内置样式: pygments, kate, monochrome, breezeDark, espresso, zenburn,
      #            haddock, tango(以及更多 pygments 主题)
      # highlight-style = "tango";

      # --- 文件与资源 ---
      # input-files: 默认输入文件列表(通常不建议在此设置, 只在特定场景使用).
      # input-files = [ "input.md" ];

      # output-file: 默认输出文件路径.
      # output-file = "output.pdf";

      # resource-path: 搜索资源(图片、CSS、过滤器等)的路径列表.
      # resource-path = [ "." "./images" "./assets" ];

      # data-dir: pandoc 数据目录(存放模板、过滤器、引用样式等).
      # data-dir = "${config.home.homeDirectory}/.local/share/pandoc";

      # --- 过滤器 ---
      # filters: 默认启用的 pandoc 过滤器列表.
      #   注意: 过滤器需要先在 package 中通过 extraPandocInputs 安装.
      # filters = [ "pandoc-crossref" "pandoc-include" ];

      # --- 变量 ---
      # variables: 设置模板中的变量值.
      #   常见变量：papersize, fontsize, mainfont, sansfont, monofont,
      #            linkcolor, urlcolor, colorlinks, geometry, linestretch,
      #            documentclass, classoption 等.
      # variables = {
      #   papersize = "a4";
      #   fontsize = "12pt";
      #   mainfont = "Noto Serif CJK SC";
      #   sansfont = "Noto Sans CJK SC";
      #   monofont = "Source Code Pro";
      #   colorlinks = true;
      #   linkcolor = "blue";
      #   urlcolor = "blue";
      # };

      # --- 其他选项 ---
      # self-contained: 是否将所有外部资源(图片、CSS、JS)嵌入到输出文件中.
      #                 生成单个 HTML 文件时很有用.
      # self-contained = false;

      # embed-resources: 是否将资源嵌入文档(类似 --self-contained).
      # embed-resources = false;

      # eol: 换行符风格. 可选: crlf, lf, native(默认).
      # eol = "lf";

      # wrap: 文本自动换行选项. 可选: auto(默认), none, preserve.
      # wrap = "auto";

      # columns: 文本宽度(每行字符数), 用于换行计算. 默认 72.
      # columns = 80;

      # dpi: 图片默认 DPI 值. 默认 96.
      # dpi = 144;

      # html-math-method: HTML 中数学公式的渲染方法.
      #   可选：mathjax, katex, mathml, webtex, gladtex, plain.
      # html-math-method = "mathjax";

      # pdf-engine-opt: 传递给 PDF 引擎的额外参数列表.
      # pdf-engine-opt = [ "-shell-escape" ];

      # pdf-engine-opts: 同上, 以字符串形式传递(会被空格分割).
      # pdf-engine-opts = "-shell-escape";

      # syntax-definition: 自定义语法高亮定义文件路径.
      # syntax-definition = "/path/to/my-language.xml";

      # abbreviations: 缩写定义文件路径(用于 LaTeX 等格式中的缩写处理).
      # abbreviations = "/path/to/abbreviations";

      # reference-doc: 参考文档(用于 docx/pptx/odt 输出时的样式参考).
      # reference-doc = "/path/to/reference.docx";

      # reference-links: 是否在 Markdown 输出中使用参考式链接.
      # reference-links = false;

      # reference-location: 参考文献位置。可选：document(文档末尾),
      #                      section(节末尾), block(块末尾).
      # reference-location = "document";

      # markdown-headings: 使用 atx 还是 setext 风格标题.
      #   可选：atx(# 风格), setext(=== 风格)
      # markdown-headings = "atx";

      # top-level-division: 顶级文档结构类型.
      #   可选: default, section, chapter, part
      # top-level-division = "chapter";

      # extract-media: 从文档中提取媒体文件的目录路径.
      # extract-media = "./media";
    };

    # -------------------------------------------------------------------
    # 4. programs.pandoc.templates (属性集, 默认 {})
    #   自定义 pandoc 模板. 键名为模板文件名(相对于 pandoc 模板目录),
    #   值为指向模板文件的 Nix 路径.
    #
    #   使用示例：
    #     templates = {
    #       "default.latex" = ./templates/my-latex-template.latex;
    #       "default.html"  = ./templates/my-html-template.html;
    #     };
    #
    #   模板可以继承 pandoc 内置模板并修改: 首先下载内置模板
    #   (pandoc -D latex > default.latex), 然后修改为你需要的样式.
    # -------------------------------------------------------------------
    templates = {
      # "default.latex" = latexTemplate;  # 自定义 LaTeX 模板
      # "default.html"  = htmlTemplate;   # 自定义 HTML 模板
    };

    # -------------------------------------------------------------------
    # 5. programs.pandoc.citationStyles (路径列表, 默认 [])
    #   要安装的 CSL(Citation Style Language)引用样式文件列表.
    #   每个元素应为指向 .csl 文件的 Nix 路径. 这些文件将被安装到
    #   ${config.home.homeDirectory}/.local/share/pandoc/csl/ 目录下.
    #
    #   使用示例:
    #     citationStyles = [
    #       ./styles/chicago-author-date.csl
    #       ./styles/ieee.csl
    #     ];
    #
    #   CSL 样式文件可从以下地址获取:
    #     https://www.zotero.org/styles
    #     https://github.com/citation-style-language/styles
    # -------------------------------------------------------------------
    citationStyles = [
      # chicagoCsl # 示例：Chicago 作者-日期引用样式
      # ieeeCsl    # 示例：IEEE 引用样式
    ];
  };

  # =========================================================================
  # 以下为只读选项, 由 Home Manager 自动生成, 无需(也不能)手动设置.
  #
  #   programs.pandoc.finalPackage (package, 只读)
  #     最终的 pandoc 包(已包装好默认参数的 pandoc 可执行文件).
  #     Home Manager 会自动将其加入 home.packages.
  #
  #   programs.pandoc.defaultsFile (绝对路径, 只读)
  #     自动生成的 defaults JSON 文件路径。
  #     该文件由 programs.pandoc.defaults 的内容自动生成.
  # =========================================================================
}
