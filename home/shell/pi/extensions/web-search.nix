# pi-web-access 搜索配置数据 —— 本文件的内容就是 ~/.pi/agent/web-search.json
#
# 部署: pi.nix 的 home.file.".pi/agent/web-search.json" 用 builtins.toJSON 转换本文件
#   后软链到该路径 (声明式只读软链: 改配置请改这里后 rebuild)。
# 包来源: ./pi/extensions/extension-groups.nix 的 init 组里的 npm:pi-web-access
#   (按项目装配, 不进全局 settings.packages)。
# 凭据: tavilyApiKey / firecrawlApiKey 写成 $VAR, 请求时从环境变量解析;
#   变量由 pi.nix 的包装脚本启动时从 sops 密钥文件读出并导出。
{
  # --- 搜索凭据 ---
  # 显式声明凭据来源便于自文档化; 环境变量优先级高于此处的字面值
  tavilyApiKey = "$TAVILY_API_KEY";
  firecrawlApiKey = "$FIRECRAWL_API_KEY";

  # --- 搜索路由 ---
  # 不设 provider (其优先级高于 searchRouting, 会覆盖路由):
  # 先用 Tavily, 失败退 Firecrawl, 再失败退 Exa (无 key 时走托管 MCP,
  # 免凭据兜底; 实测 mcp.exa.ai 可直连)。
  # fallbackOn 决定哪类错误继续尝试下一个 provider; 它不含凭据类错误,
  # 所以 key 配错不会继续回退, 而是就地返回诊断
  searchRouting = {
    providers = [
      "tavily"
      "firecrawl"
      "exa"
    ];
    fallbackOn = [
      "transient"
      "quota"
      "network"
      "invalid-response"
    ];
  };

  # --- 交互与快捷键 ---
  # none: web_search 直接返回原始结果, 不弹浏览器策展窗口
  workflow = "none";
  # 两个默认键都被 kitty 拦截 (2026-10-04 核实, 规则见 home/desktop/kitty.nix):
  #   curate   ctrl+shift+s → kitty 的 search_scrollback
  #   activity ctrl+shift+w → kitty 的 close_window (按一下直接关窗口)
  # 故一并改到 kitty 层空闲的 alt 键。注: 扩展注册的是字面量键, 不能用
  # keybindings.json 改, 只能在这里改 (本文件经 builtins.toJSON 部署为只读 json)。
  shortcuts = {
    curate = "alt+u";
    activity = "alt+a";
  };

  # --- 工具 / 命令 / 图片开关 (显式写出, 便于日后核对) ---
  tools = {
    webSearch.enabled = true;
    sourceCheck.enabled = true;
    fetchContent.enabled = true;
    getSearchContent.enabled = true;
  };
  commands = {
    websearch.enabled = true;
    curator.enabled = true;
    search.enabled = true;
    "google-account".enabled = true;
  };
  image.enabled = true;

  # --- 内容提取 ---
  # fetch_content 内联切片, 同时是 get_search_content 的默认/最大切片
  maxInlineContentChars = 30000;
  fetch.timeout = 30;
  # 无 Datalab / Gemini key, auto 会落到本地 unpdf (纯文本, 离线免费)
  pdf = {
    provider = "auto";
    maxSizeMB = 20;
    maxPages = 100;
  };

  # --- GitHub ---
  # 公共库直接 clone 到本地; 超过 350MB 走 API 轻量视图
  # gh CLI 由 pi.nix 的 programs.pi-coding-agent.extraPackages 提供,
  # 认证靠 sops.nix 注入的 GH_TOKEN;
  # 未认证或 gh 失败时 PR/Issue 降级到未认证 REST (仅公共库, 限流 60/h, 无 checks)
  githubClone = {
    enabled = true;
    maxRepoSizeMB = 350;
    cloneTimeoutSeconds = 30;
  };
  githubPrIssue.enabled = true;

  # --- 视频 ---
  # 无 GEMINI_API_KEY / Gemini Web cookie / Perplexity key 时, YouTube 与本地视频
  # 分析都会失败, 但 enabled = true 会返回明确可操作的报错
  # ("Sign into Google ... or set GEMINI_API_KEY"), 优于静默退化成普通网页抓取。
  # 注意: 本地视频抽帧受 video.enabled 门控; YouTube 抽帧只受 image.enabled 门控,
  # 用 yt-dlp + ffmpeg 本地完成, 不需要 API key。
  youtube.enabled = true;
  video.enabled = true;

  # --- SSRF ---
  # 保持默认为空: 本机 v2raya 未使用 TUN/fake-IP (公共域名解析到真实 IP),
  # 无需豁免 198.18.0.0/15 等保留段; 保留完整 SSRF 防护
}
