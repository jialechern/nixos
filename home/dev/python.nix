{ config, pkgs, ... }:

{
  # --- --- --- --- --- --- 常用的全局 python 库 --- --- --- --- --- ---
  home.packages = [
    # 使用 withPackages 创建一个包含常用库的 Python 环境, 它接收一个 lambda
    (pkgs.python3.withPackages (python-set: with python-set; [
      python-magic # 文件类型检测
      polars # 高性能数据处理 (比 pandas 更现代)
      numpy
      matplotlib # 绘图库
      pandas # 虽然有了 polars, 但在处理某些旧格式时依然是行业标准
      requests # 几乎所有 Python 项目都会用到的 HTTP 库
      sympy # 符号计算库
      scipy # 科学计算库

      # --- PDF skill 依赖 ---
      # 来源标注: [pdf] = anthropics/skills 官方 pdf; [pdf-parser] = memtomem
      # pdf-parser (均部署于 ~/.agents/skills, 见 home/skills.nix);
      # 移除对应 skill 时同步清理; 系统侧配套 CLI (poppler/qpdf/tesseract)
      # 在 home/shell.nix, 不要重复安装
      pypdf # [pdf] 合并/拆分/旋转/加密/水印/表单 (基础操作主力)
      pdfplumber # [pdf]+[pdf-parser] 文本/表格提取 (读 PDF 主力)
      pymupdf # [pdf-parser] 文本层抽取与页面渲染主力 (fitz)
      reportlab # [pdf] 新建/排版 PDF (生成主力)
      pypdfium2 # [pdf] reference: 高速渲染/批量出图 (PDFium 绑定, 视觉校验用)
      pytesseract # [pdf] OCR 封装 (需系统 tesseract 二进制)
      pdf2image # [pdf] PDF→PNG (OCR/表单 渲染前置, 需系统 poppler)
      openpyxl # [pdf] 表格导出 Excel (pandas.to_excel 后端)
      camelot # [pdf-parser] 可选: 框线表格高保真提取; 自动带入 opencv-python-headless
      #          (cv2 可直接 import), 这是 opencv 在全配置中的唯一用途; pdf2docx 已移出 shell.nix
      #          如不再需要框线表格, 删本行即可连带去掉 opencv
      pillow # 图像处理 (pdf2image/pypdfium2 的 PIL 图像均依赖它)
    ]))

    pkgs.ruff
  ];

  # --- --- --- --- --- --- uv 配置 --- --- --- --- --- ---
  programs.uv = {
    enable = true;
    # 默认使用系统中的 uv 包, 也可以手动指定版本
    package = pkgs.uv;

    # 核心配置 (对应 uv.toml)
    settings = {
      # --- Python 策略 ---
      # 偏好使用系统中安装的 Python(例如通过 Nix 安装的)
      # 但也允许 uv 自动下载并管理隔离的 Python 版本
      python-preference = "managed";

      # --- 缓存与路径 ---
      # 明确指定缓存目录, 便于管理和清理
      cache-dir = "${config.home.homeDirectory}/.cache/uv";

      # --- 交互优化 ---
      # 从系统证书存储加载根证书 (native-tls 已废弃, 官方建议改用 system-certs)
      # 对依赖代理/自签根证书的受限网络环境更稳定
      system-certs = true;

      # uv 在找不到 Python 时自动下载 (可选值: automatic / manual / never)
      python-downloads = "automatic";

      # --- 默认索引 (PyPI 镜像) ---
      # index-url 已废弃, 改用 index 表; 注意镜像 URL 会写入 uv.lock
      index = [
        {
          url = "https://pypi.tuna.tsinghua.edu.cn/simple";
          default = true;
        }
      ];

      # --- 解释器下载镜像 ---
      # uv 默认从 GitHub (python-build-standalone) 下载托管 Python,
      # 大陆直连慢; 换南京大学镜像 (替换 releases/download 前缀)
      # 验证: uv python install 3.13
      python-install-mirror = "https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone/";

      # --- 编译与链接 ---
      # 解决 NixOS 上一些 binary 无法运行的常见问题
      # 强制 uv 在安装时尝试链接到系统库(如果需要)
      compile-bytecode = true;
    };
  };

  # --- --- --- --- --- --- mypy 配置 --- --- --- --- --- ---
  programs.mypy = {
    enable = true;

    package = pkgs.mypy;

    # --- --- --- 核心设置 --- --- ---
    settings = {
      mypy = {
        # --- 基础运行环境 ---
        python_version = "3.14";
        # 开启增量检查，提升二次扫描速度
        incremental = true;
        # 缓存路径
        cache_dir = ".mypy_cache";

        # --- 严格检查规则 ---
        # 开启全套严格模式
        strict = true;
        # 即使函数没写注解, 也要检查其内部逻辑
        check_untyped_defs = true;
        # 强制所有函数定义必须有类型注解
        disallow_untyped_defs = true;
        # 禁止不完整的注解(比如漏写返回值)
        disallow_incomplete_defs = true;
        # 禁止调用没有注解的函数
        disallow_untyped_calls = true;
        # 禁止继承自 Any 类型，防止类型系统被击穿
        disallow_subclassing_any = true;
        # 禁止隐式 Optional (如 arg: str = None)
        no_implicit_optional = true;
        # 启用严格的等号检查(防止不同类型误用 ==)
        strict_equality = true;

        # --- 警告与代码质量 ---
        # 警告那些不再需要的 # type: ignore
        warn_unused_ignores = true;
        # 当函数本该有明确类型却返回 Any 时报错
        warn_return_any = true;
        # 发现永远跑不到的代码(Dead Code)时报错
        warn_unreachable = true;
        # 警告不必要的强制类型转换
        warn_redundant_casts = true;
        # 警告配置文件中没用上的设置项
        warn_unused_configs = true;

        # --- 导入与第三方库处理 ---
        ignore_missing_imports = true; # 忽略找不到类型信息的库（还原你原有的设置）
        follow_imports = "normal"; # 正常的导入跟踪行为

        # --- 优化错误提示 ---
        # 坐标精准定位: 显示错误发生的具体列号
        show_column_numbers = true;

        # 增强视觉体验: 在报错时显示上下文代码片段
        show_error_context = true;

        # 错误代码可见: 显示具体的错误类型(如 [import-untyped]), 方便屏蔽
        show_error_codes = true;

        # 优化输出: 使用颜色和更直观的格式输出错误
        pretty = true;

        # 增强稳定性: 禁止变量名重定义(例如禁止先定义 s: str 再定义 s: int)
        allow_redefinition = false;

        # 局部类型推断优化: 允许更智能的局部变量类型推断
        local_partial_types = true;
      };

      # # 如果以后有针对特定库的配置, 可以继续在 settings 里添加
      # # 例如处理没有类型注解的第三方库:
      # "mypy-requests" = {
      #	 ignore_missing_imports = true;
      # };
    };
  };
}
