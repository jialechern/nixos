{ config, pkgs, ... }:

{
  # --- --- --- 依赖程序 --- --- ---
  home.packages = with pkgs; [
    neovim-remote
  ];

  # --- --- --- zathura 配置 --- --- ---
  programs.zathura = {
    enable = true;

    package = pkgs.zathura;

    # --- --- --- 变量设置 (options) --- --- ---
    options = {
      # --- 基础与界面 ---
      guioptions = ""; # 隐藏所有不必要的原生 GUI 元素 (状态栏等)
      database = "sqlite"; # 使用 sqlite 存储历史记录和书签
      zoom-center = true; # 缩放时以屏幕中心为基准
      vertical-center = true; # 打开或跳转时垂直居中
      first-page-column = "1"; # 双页模式下, 第一页单独作为一列显示

      # --- 边距与步长 ---
      page-v-padding = 10; # 页面垂直间距
      page-h-padding = 3; # 页面水平间距
      statusbar-h-padding = 8; # 状态栏水平内边距
      statusbar-v-padding = 2; # 状态栏垂直内边距
      scroll-hstep = -1; # 垂直滚动步长 (-1 表示平滑)
      scroll-step = 40; # 水平滚动步长
      zoom-step = 10; # 缩放步长

      # --- 系统与行为 ---
      window-title-basename = true; # 窗口标题仅显示文件名，不显示完整路径
      selection-clipboard = "clipboard"; # 选中文本自动进入系统剪贴板 (Wayland 必备)
      adjust-open = "width"; # 打开文件时默认宽度适应窗口

      # 平滑滚动: 现代触摸板或高刷屏必备
      smooth-scroll = true;

      # 窗口标题: 在窗口管理器（如 Niri/Sway）的顶栏显示当前页码
      window-title-page = true;

      # 禁用沙盒: 在 Arch/Wayland 下, 严格的沙盒可能导致无法调用外部编辑器或读取特定字体
      sandbox = "none";

      # SyncTeX 支持: 为 LaTeX / Typst 工作流开启正反向搜索核心
      synctex = true;

      # 定义反向搜索触发时的命令(按 Ctrl + 左键点击 PDF 即可跳回 Neovim 对应代码行)
      # 这里使用 neovim-remote (nvr), 需要确保已安装 neovim-remote 包
      synctex-editor-command = "nvr --remote-silent %f -c %l";

      # ==================== Dracula 主题 (Dark Mode) ====================
      # 默认启动时开启反色模式 (即开启暗色主题)
      recolor = true;

      notification-error-bg = "rgba(255,85,85,1)"; # Red
      notification-error-fg = "rgba(248,248,242,1)"; # Foreground
      notification-warning-bg = "rgba(255,184,108,1)"; # Orange
      notification-warning-fg = "rgba(68,71,90,1)"; # Selection
      notification-bg = "rgba(40,42,54,1)"; # Background
      notification-fg = "rgba(248,248,242,1)"; # Foreground

      completion-bg = "rgba(40,42,54,1)"; # Background
      completion-fg = "rgba(98,114,164,1)"; # Comment
      completion-group-bg = "rgba(40,42,54,1)"; # Background
      completion-group-fg = "rgba(98,114,164,1)"; # Comment
      completion-highlight-bg = "rgba(68,71,90,1)"; # Selection
      completion-highlight-fg = "rgba(248,248,242,1)"; # Foreground

      index-bg = "rgba(40,42,54,1)"; # Background
      index-fg = "rgba(248,248,242,1)"; # Foreground
      index-active-bg = "rgba(68,71,90,1)"; # Current Line
      index-active-fg = "rgba(248,248,242,1)"; # Foreground

      inputbar-bg = "rgba(40,42,54,1)"; # Background
      inputbar-fg = "rgba(248,248,242,1)"; # Foreground
      statusbar-bg = "rgba(40,42,54,1)"; # Background
      statusbar-fg = "rgba(248,248,242,1)"; # Foreground

      highlight-color = "rgba(255,184,108,0.5)"; # Orange
      highlight-active-color = "rgba(255,121,198,0.5)"; # Pink

      default-bg = "rgba(40,42,54,1)"; # Background
      default-fg = "rgba(248,248,242,1)"; # Foreground

      render-loading = true;
      render-loading-bg = "rgba(40,42,54,1)";
      render-loading-fg = "rgba(248,248,242,1)";

      # --- 反色模式下的背景和前景颜色 ---
      recolor-lightcolor = "rgba(40,42,54,1)"; # Background
      recolor-darkcolor = "rgba(248,248,242,1)"; # Foreground
    };

    # --- --- --- 多模式键位映射 (extraConfig) --- --- ---
    # 因为涉及 index/fullscreen/presentation 等多种特定模式, 使用原生配置块注入最为安全
    extraConfig = ''
      			# --- --- --- 基础快捷键 --- --- ---
      			map [normal] \\ display_link
      			map [fullscreen] \\ display_link
      			map [presentation] \\ display_link

      			unmap [normal] q
      			unmap [index] q
      			unmap [fullscreen] q
      			unmap [presentation] q
      			map [normal] Q quit
      			map [index] Q quit
      			map [fullscreen] Q quit
      			map [presentation] Q quit

      			# --- --- --- 链接与跳转 --- --- ---
      			map [normal] @ follow
      			map [index] @ follow
      			map [fullscreen] @ follow
      			map [presentation] @ follow

      			map [normal] R reload
      			map [index] R reload
      			map [fullscreen] R reload
      			map [presentation] R reload

      			map [normal] O file_chooser
      			map [index] O file_chooser
      			map [fullscreen] O file_chooser
      			map [presentation] O file_chooser

      			# --- --- --- 界面切换 --- --- ---
      			map [normal] I toggle_inputbar
      			map [index] I toggle_inputbar
      			map [fullscreen] I toggle_inputbar
      			map [presentation] I toggle_inputbar

      			map [normal] d toggle_page_mode
      			map [index] d toggle_page_mode
      			map [fullscreen] d toggle_page_mode
      			map [presentation] d toggle_page_mode

      			map [normal] B toggle_statusbar
      			map [index] B toggle_statusbar
      			map [fullscreen] B toggle_statusbar
      			map [presentation] B toggle_statusbar

      			# --- --- --- 书签与主题 --- --- ---
      			map [normal] m mark_add
      			map [index] m mark_add
      			map [fullscreen] m mark_add
      			map [presentation] m mark_add

      			map [normal] ` mark_evaluate
      			map [index] ` mark_evaluate
      			map [fullscreen] ` mark_evaluate
      			map [presentation] ` mark_evaluate

      			unmap [normal] r
      			unmap [index] r
      			unmap [fullscreen] r
      			unmap [presentation] r
      			map [normal] r recolor
      			map [index] r recolor
      			map [fullscreen] r recolor
      			map [presentation] r recolor

      			# --- --- --- 模式切换 --- --- ---
      			map [normal] F toggle_fullscreen
      			map [index] F toggle_fullscreen
      			map [fullscreen] F toggle_fullscreen
      			map [presentation] F toggle_fullscreen

      			map [normal] P toggle_presentation
      			map [index] P toggle_presentation
      			map [fullscreen] P toggle_presentation
      			map [presentation] P toggle_presentation

      			map [normal] Tab toggle_index
      			map [index] Tab toggle_index
      			map [fullscreen] Tab toggle_index
      			map [presentation] Tab toggle_index

      			map [normal] C toggle_index
      			map [index] C toggle_index
      			map [fullscreen] C toggle_index
      			map [presentation] C toggle_index

      			map [normal] Esc abort
      			map [index] Esc abort
      			map [fullscreen] Esc abort
      			map [presentation] Esc abort

      			# --- --- --- 快速跳转 --- --- ---
      			map [normal] gg goto top
      			map [index] gg goto top
      			map [fullscreen] gg goto top
      			map [presentation] gg goto top

      			map [normal] G goto bottom
      			map [index] G goto bottom
      			map [fullscreen] G goto bottom
      			map [presentation] G goto bottom

      			map [normal] U scroll page-top
      			map [index] U scroll page-top
      			map [fullscreen] U scroll page-top
      			map [presentation] U scroll page-top

      			map [normal] D scroll page-bottom
      			map [index] D scroll page-bottom
      			map [fullscreen] D scroll page-bottom
      			map [presentation] D scroll page-bottom

      			# --- --- --- 垂直滚动 --- --- ---
      			map [normal] k scroll up
      			map [fullscreen] k scroll up
      			map [presentation] k scroll up

      			map [normal] K scroll half-up
      			map [fullscreen] K scroll half-up
      			map [presentation] K scroll half-up

      			map [normal] b scroll half-up
      			map [fullscreen] b scroll half-up
      			map [presentation] b scroll half-up

      			map [normal] , navigate previous
      			map [fullscreen] , navigate previous
      			map [presentation] , navigate previous

      			map [normal] PageUp navigate previous
      			map [fullscreen] PageUp navigate previous
      			map [presentation] PageUp navigate previous

      			map [normal] j scroll down
      			map [fullscreen] j scroll down
      			map [presentation] j scroll down

      			map [normal] J scroll half-down
      			map [fullscreen] J scroll half-down
      			map [presentation] J scroll half-down
      			map [normal] w scroll half-down
      			map [fullscreen] w scroll half-down
      			map [presentation] w scroll half-down

      			map [normal] . navigate next
      			map [fullscreen] . navigate next
      			map [presentation] . navigate next
      			map [normal] PageDown navigate next
      			map [fullscreen] PageDown navigate next
      			map [presentation] PageDown navigate next

      			# --- --- --- 水平滚动 --- --- ---
      			map [normal] h scroll left
      			map [fullscreen] h scroll left
      			map [presentation] h scroll left

      			map [normal] H scroll half-left
      			map [fullscreen] H scroll half-left
      			map [presentation] H scroll half-left

      			map [normal] ^ scroll full-left
      			map [fullscreen] ^ scroll full-left
      			map [presentation] ^ scroll full-left

      			map [normal] l scroll right
      			map [fullscreen] l scroll right
      			map [presentation] l scroll right

      			map [normal] L scroll half-right
      			map [fullscreen] L scroll half-right
      			map [presentation] L scroll half-right

      			map [normal] $ scroll full-right
      			map [fullscreen] $ scroll full-right
      			map [presentation] $ scroll full-right

      			# --- --- --- 索引模式 (Index) --- --- ---
      			map [index] k navigate_index up
      			map [index] j navigate_index down
      			map [index] l navigate_index expand
      			map [index] L navigate_index expand-all
      			map [index] h navigate_index collapse
      			map [index] H navigate_index collapse-all
      			map [index] J navigate_index half-down
      			map [index] K navigate_index half-up
      			map [index] f navigate_index toggle
      			map [index] Return navigate_index select

      			# --- --- --- 搜索 --- --- ---
      			map [normal] // search forward
      			map [index] // search forward
      			map [fullscreen] // search forward
      			map [presentation] // search forward

      			map [normal] ?? search backward
      			map [index] ?? search backward
      			map [fullscreen] ?? search backward
      			map [presentation] ?? search backward

      			# --- --- --- 页面缩放与调整 --- --- ---
      			map [normal] = zoom in
      			map [fullscreen] = zoom in
      			map [presentation] = zoom in

      			map [normal] - zoom out
      			map [fullscreen] - zoom out
      			map [presentation] - zoom out

      			map [normal] Z adjust_window best-fit
      			map [index] Z adjust_window best-fit
      			map [fullscreen] Z adjust_window best-fit
      			map [presentation] Z adjust_window best-fit

      			map [normal] z adjust_window width
      			map [index] z adjust_window width
      			map [fullscreen] z adjust_window width
      			map [presentation] z adjust_window width

      			map [normal] | adjust_window width
      			map [fullscreen] | adjust_window width
      			map [presentation] | adjust_window width

      			# --- --- --- 旋转页面 --- --- ---
      			map [normal] T rotate rotate-ccw
      			map [fullscreen] T rotate rotate-ccw
      			map [presentation] T rotate rotate-ccw

      			map [normal] t rotate rotate-cw
      			map [fullscreen] t rotate rotate-cw
      			map [presentation] t rotate rotate-cw

      			# --- --- --- Jumplist 跳转 --- --- ---
      			unmap [normal] i
      			unmap [fullscreen] i
      			unmap [presentation] i

      			map [normal] i jumplist forward
      			map [fullscreen] i jumplist forward
      			map [presentation] i jumplist forward

      			unmap [normal] o
      			unmap [fullscreen] o
      			unmap [presentation] o

      			map [normal] o jumplist backward
      			map [fullscreen] o jumplist backward
      			map [presentation] o jumplist backward

      			# --- --- --- 奇偶页切换 (右至左) --- --- ---
      			unmap [normal] v
      			unmap [index] v
      			unmap [fullscreen] v
      			unmap [presentation] v

      			unmap [normal] V
      			unmap [index] V
      			unmap [fullscreen] V
      			unmap [presentation] V

      			map [normal] v set page-right-to-left
      			map [normal] V set page-right-to-left
      			map [index] v set page-right-to-left
      			map [index] V set page-right-to-left
      			map [fullscreen] v set page-right-to-left
      			map [fullscreen] V set page-right-to-left
      			map [presentation] v set page-right-to-left
      			map [presentation] V set page-right-to-left
      		'';
  };
}
