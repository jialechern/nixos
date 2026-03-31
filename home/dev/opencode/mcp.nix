{
	# =========================================================
	# 非官方 MCP
	# =========================================================

    context7 = {
        type = "local";
        command = [ "context7-mcp" ];
        enabled = true;

        environment = {
            CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
    };

    firecrawl = {
        type = "local";
        command = [ "firecrawl-mcp" ];
        enabled = true;

        environment = {
            FIRECRAWL_API_KEY = "{env:FIRECRAWL_API_KEY}";
        };
    };

    tavily = {
        type = "local";
        command = [ "tavily-mcp" ];
        enabled = true;

        environment = {
            TAVILY_API_KEY = "{env:TAVILY_API_KEY}";
        };
    };

    baidu_maps = {
        type = "local";
        command = [ "mcp_server_baidu_maps" ];
        enabled = false;

        environment = {
            BAIDU_MAPS_API_KEY = "{env:BAIDU_MAPS_API_KEY}";
            BAIDU_MAP_API_KEY = "{env:BAIDU_MAP_API_KEY}";
        };
    };

	# =========================================================
	# MCP 官方仓库里的 reference servers
	# =========================================================

	# Filesystem: 适合让 agent 读写仓库内文件
	filesystem = {
		type = "local";
		command = [ "filesystem-mcp" ];
		enabled = false;
	};

	# Git: 适合做 git 仓库读写 / 变更分析
	git = {
		type = "local";
		command = [ "mcp-server-git" "--repository" "$WORK_REPO" ];
		enabled = false;
	};

	# Fetch: 轻量网页抓取, 比重型浏览器工具更省上下文
	fetch = {
		type = "local";
		command = [ "mcp-server-fetch" ];
		enabled = true;
	};

	# Memory: 跨会话记忆, 适合长期项目, 但要控制上下文污染
	memory = {
		type = "local";
		command = [ "mcp-server-memory" ];
		enabled = true;
	};

	# Sequential Thinking: 适合把复杂任务拆成步骤
	sequential-thinking = {
		type = "local";
		command = [ "mcp-server-sequential-thinking" ];
		enabled = true;
	};

	# Time: 时区 / 时间换算
	time = {
		type = "local";
		command = [ "mcp-server-time" ];
		enabled = true;
	};
}
