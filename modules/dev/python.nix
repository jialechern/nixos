{ config, pkgs, ... }:

{
    # --- --- --- --- --- --- 常用的全局 python 库 --- --- --- --- --- ---
		home.packages = [
		# 使用 withPackages 创建一个包含常用库的 Python 环境, 它接收一个 lambda
		(pkgs.python3.withPackages (python-set: with python-set; [
			python-magic # 文件类型检测
			polars       # 高性能数据处理 (比 pandas 更现代)
			scipy        # 科学计算
			sympy        # 符号计算(代数运算)

			matplotlib   # 配合 scipy/sympy 进行绘图可视化
			pandas       # 虽然有了 polars, 但在处理某些旧格式时依然是行业标准
			requests     # 几乎所有 Python 项目都会用到的 HTTP 库
		]))
	];

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
