{ config, pkgs, ... }:

{
  programs.htop = {
    enable = true;

    # =========================================================
    # htop 核心配置
    # =========================================================
    settings = {

      # ---------- 颜色与外观 ----------

      # 配色方案: 0=Default, 1=Monochrome, 2=BlackOnWhite,
      # 3=LightTerminal, 4=Midnight, 5=BlackNight, 6=Bright
      color_scheme = 6;

      # 顶部页眉布局；可选 two_50_50 / two_33_67 / two_67_33 /
      # three_33_33_33 / three_25_25_50 / three_25_50_25 /
      # three_50_25_25 / four_25_25_25_25
      header_layout = "two_50_50";

      # 页眉边距(行)
      header_margin = 0;

      # 隐藏底部功能键提示栏; 0=显示 1=隐藏
      hide_function_bar = 0;

      # ---------- 刷新与延迟 ----------

      # 刷新间隔(单位: 0.1 秒); 15 表示 1.5 秒
      delay = 15;

      # 更新进程名称
      update_process_names = 0;

      # ---------- CPU 显示 ----------

      # 是否将 Guest 时间计入 CPU meter
      account_guest_in_cpu_meter = 0;

      # CPU 编号从 1 开始(而非 0)
      cpu_count_from_one = 1;

      # 显示详细的 CPU 时间(system/user/io 等)
      detailed_cpu_time = 0;

      # 显示 CPU 使用率
      show_cpu_usage = 1;

      # 显示 CPU 频率
      show_cpu_frequency = 0;

      # 显示 CPU 温度（需要传感器支持）
      show_cpu_temperature = 0;

      # 温度单位使用华氏度；0=摄氏度
      degree_fahrenheit = 0;

      # ---------- 进程列表显示 ----------

      # 高亮显示进程文件名(去掉路径前缀)
      highlight_base_name = 1;

      # 以 MB 为单位高亮显示内存大小
      highlight_megabytes = 1;

      # 高亮显示线程
      highlight_threads = 0;

      # 高亮发生变化的值
      highlight_changes = 0;

      # 高亮变化延迟(秒)
      highlight_changes_delay_secs = 5;

      # 高亮已删除的可执行文件
      highlight_deleted_exe = 1;

      # 隐藏内核线程
      hide_kernel_threads = 1;

      # 隐藏用户态线程；0=显示
      hide_userland_threads = 0;

      # 隐藏容器内运行的进程
      hide_running_in_container = 0;

      # 阴影化其他用户的进程(需要特权)
      shadow_other_users = 0;

      # 显示线程名称
      show_thread_names = 0;

      # 显示程序的完整路径
      show_program_path = 1;

      # 阴影化发行版路径前缀
      shadow_distribution_path_prefix = 0;

      # 在 cmdline 中查找命令名
      find_comm_in_cmdline = 1;

      # 从 cmdline 中去除可执行文件前缀
      strip_exe_from_cmdline = 1;

      # 显示合并命令(进程树)
      show_merged_command = 0;

      # ---------- 交互与操作 ----------

      # 启用鼠标支持
      enable_mouse = 1;

      # 显示屏幕切换标签页
      screen_tabs = 1;

      # ---------- 树形视图 ----------

      # 默认使用树形视图
      tree_view = 0;

      # 树形视图始终按 PID 排序
      tree_view_always_by_pid = 0;

      # 所有分支折叠
      all_branches_collapsed = 0;

      # ---------- 排序 ----------

      # 排序键(字段 ID): PERCENT_CPU=46 PERCENT_MEM=47 TIME=49 PID=0
      sort_key = 46;

      # 排序方向: 1=升序 -1=降序
      sort_direction = -1;

      # 树形视图排序键
      tree_sort_key = 0;

      # 树形视图排序方向
      tree_sort_direction = 1;

      # ---------- 拓扑亲和性 ----------

      # 显示 NUMA 节点 / CPU 拓扑亲和性
      topology_affinity = 0;

      # =========================================================
      # 默认 left_meters 与 right_meters(通过 helper 生成)
      #
      # 可用 meter 类型：
      #   bar  name  → 条形图( 模式 1 )
      #   text name  → 纯文本( 模式 2 )
      #   graph name → 折线图( 模式 3 )
      #   led  name  → LED 灯( 模式 4 )
      #   blank      → 空位占位符
      #
      # 常用 meter 名称：
      #   CPU, AllCPUs, AllCPUs2/4/8, LeftCPUs, RightCPUs,
      #   Memory, Swap, Zram, DiskIO, NetworkIO,
      #   Tasks, LoadAverage, Uptime, Systemd,
      #   Hostname, Clock, Date, DateTime, Battery
      # =========================================================
    }
    // (with config.lib.htop; leftMeters [
      (bar "LeftCPUs")
      (bar "Memory")
      (bar "Swap")
      (bar "NetworkIO")
    ])
    // (with config.lib.htop; rightMeters [
      (bar "RightCPUs")
      (text "Tasks")
      (text "LoadAverage")
      (text "Uptime")
    ])

    # =========================================================
    # 默认进程列表列(Main screen)
    #
    # 常用字段:
    #   PID, USER, PRIORITY, NICE, M_VIRT (虚拟内存),
    #   M_RESIDENT (物理内存), M_SHARE (共享内存),
    #   STATE, PERCENT_CPU, PERCENT_MEM, TIME, COMM
    # =========================================================
    // {
      fields = with config.lib.htop.fields; [
        PID          # 进程 ID
        USER         # 用户名
        PRIORITY     # 内核优先级
        NICE         # Nice 值
        M_VIRT       # 虚拟内存( VIRT )
        M_RESIDENT   # 物理内存( RES )
        M_SHARE      # 共享内存( SHR )
        STATE        # 进程状态( S/R/D/Z/… )
        PERCENT_CPU  # CPU 占用率
        PERCENT_MEM  # 内存占用率
        TIME         # 累计 CPU 时间
        COMM         # 命令名
      ];
    };
  };
}
