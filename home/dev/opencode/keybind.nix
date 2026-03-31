{
    # leader: 快捷键前缀; 官方默认是 ctrl+x, 大多数动作都先按它再按后续键位
    leader = "ctrl+o";

    # app_exit: 退出 OpenCode; 对应官方 /exit ( 别名 /quit、/q )
    app_exit = "ctrl+c,ctrl+q,ctrl+d,<leader>q";

    # editor_open: 打开外部编辑器撰写消息; 对应官方 /editor
    editor_open = "<leader>e";

    # theme_list: 列出/切换主题; 对应官方 /themes
    theme_list = "<leader>t";

    # sidebar_toggle: 切换侧边栏显示
    sidebar_toggle = "<leader>b";

    # scrollbar_toggle: 切换滚动条显示
    scrollbar_toggle = "none";

    # username_toggle: 切换用户名显示; 官方 TUI 自定义里有"username display", 且会跨会话记住
    username_toggle = "none";

    # status_view: 打开状态/状态栏视图
    status_view = "<leader>s";

    # tool_details: 切换工具执行详情; 对应官方 /details
    tool_details = "none";

    # session_export: 导出当前会话为 Markdown; 对应官方 /export
    session_export = "<leader>x";

    # session_new: 新建会话; 对应官方 /new ( 别名 /clear )
    session_new = "<leader>n";

    # session_list: 列出并切换会话; 对应官方 /sessions( 别名 /resume、/continue )
    session_list = "<leader>l";

    # session_timeline: 打开会话时间线
    session_timeline = "<leader>g";

    # session_fork: 分叉当前会话
    session_fork = "none";

    # session_rename: 重命名当前会话
    session_rename = "none";

    # session_share: 共享当前会话; 对应官方 /share
    session_share = "none";

    # session_unshare: 取消共享当前会话; 对应官方 /unshare
    session_unshare = "none";

    # session_interrupt: 中断当前会话/正在进行的响应; 这里用 escape
    session_interrupt = "escape";

    # session_compact: 压缩当前会话上下文; 对应官方 /compact( 别名 /summarize )
    session_compact = "<leader>c";

    # session_child_first: 跳到第一个子会话; 官方默认是 leader+down
    session_child_first = "<leader>down";

    # session_child_cycle: 在子会话之间向前切换
    session_child_cycle = "<leader>right";

    # session_child_cycle_reverse: 在子会话之间向后切换
    session_child_cycle_reverse = "<leader>left";

    # session_parent: 返回父会话
    session_parent = "<leader>up";

    # messages_page_up: 消息区向上翻页
    messages_page_up = "pageup,ctrl+alt+b";

    # messages_page_down: 消息区向下翻页
    messages_page_down = "pagedown,ctrl+alt+f";

    # messages_line_up: 消息区向上滚动一行
    messages_line_up = "ctrl+alt+y";

    # messages_line_down: 消息区向下滚动一行
    messages_line_down = "ctrl+alt+e";

    # messages_half_page_up: 消息区向上滚动半页
    messages_half_page_up = "ctrl+alt+u";

    # messages_half_page_down: 消息区向下滚动半页
    messages_half_page_down = "ctrl+alt+d";

    # messages_first: 跳到第一条消息
    messages_first = "ctrl+g,home";

    # messages_last: 跳到最后一条消息
    messages_last = "ctrl+alt+g,end";

    # messages_next: 下一条消息
    messages_next = "none";

    # messages_previous: 上一条消息
    messages_previous = "none";

    # messages_copy: 复制当前消息内容
    messages_copy = "<leader>y";

    # messages_undo: 撤销上一条消息/上一步改动; 对应官方 /undo
    messages_undo = "<leader>u";

    # messages_redo: 重做刚刚撤销的内容; 对应官方 /redo
    messages_redo = "<leader>r";

    # messages_last_user: 跳到最后一条用户消息
    messages_last_user = "none";

    # messages_toggle_conceal: 切换消息中的隐藏/展开显示
    messages_toggle_conceal = "<leader>h";

    # model_list: 列出可用模型; 对应官方 /models
    model_list = "<leader>m";

    # model_cycle_recent: 在最近使用的模型间切换
    model_cycle_recent = "f2";

    # model_cycle_recent_reverse: 反向切换最近使用的模型
    model_cycle_recent_reverse = "shift+f2";

    # model_cycle_favorite: 在收藏模型间切换
    model_cycle_favorite = "none";

    # model_cycle_favorite_reverse: 反向切换收藏模型
    model_cycle_favorite_reverse = "none";

    # variant_cycle: 切换模型变体; 官方说明 ctrl+t 用来切换模型变体/推理能力
    variant_cycle = "ctrl+t";

    # command_list: 打开命令列表/命令面板
    command_list = "ctrl+p";

    # agent_list: 打开 Agent 列表
    agent_list = "<leader>a";

    # agent_cycle: 在 Agent 之间向前切换
    agent_cycle = "tab";

    # agent_cycle_reverse: 在 Agent 之间向后切换
    agent_cycle_reverse = "shift+tab";

    # input_clear: 清空输入框
    input_clear = "ctrl+c";

    # input_paste: 粘贴到输入框
    input_paste = "ctrl+v";

    # input_submit: 提交当前输入; 官方文档对应 enter/return
    input_submit = "return";

    # input_newline: 在输入框里插入换行
    input_newline = "shift+return,ctrl+return,alt+return,ctrl+j";

    # input_move_left: 光标左移一格
    input_move_left = "left,ctrl+b";

    # input_move_right: 光标右移一格
    input_move_right = "right,ctrl+f";

    # input_move_up: 光标上移
    input_move_up = "up";

    # input_move_down: 光标下移
    input_move_down = "down";

    # input_select_left: 向左选中
    input_select_left = "shift+left";

    # input_select_right: 向右选中
    input_select_right = "shift+right";

    # input_select_up: 向上选中
    input_select_up = "shift+up";

    # input_select_down: 向下选中
    input_select_down = "shift+down";

    # input_line_home: 跳到当前行开头
    input_line_home = "ctrl+a";

    # input_line_end: 跳到当前行结尾
    input_line_end = "ctrl+e";

    # input_select_line_home: 选中到行首
    input_select_line_home = "ctrl+shift+a";

    # input_select_line_end: 选中到行尾
    input_select_line_end = "ctrl+shift+e";

    # input_visual_line_home: 可视模式下跳到行首
    input_visual_line_home = "alt+a";

    # input_visual_line_end: 可视模式下跳到行尾
    input_visual_line_end = "alt+e";

    # input_select_visual_line_home: 选中到可视行首
    input_select_visual_line_home = "alt+shift+a";

    # input_select_visual_line_end: 选中到可视行尾
    input_select_visual_line_end = "alt+shift+e";

    # input_buffer_home: 跳到输入缓冲区开头
    input_buffer_home = "home";

    # input_buffer_end: 跳到输入缓冲区末尾
    input_buffer_end = "end";

    # input_select_buffer_home: 选中到输入缓冲区开头
    input_select_buffer_home = "shift+home";

    # input_select_buffer_end: 选中到输入缓冲区末尾
    input_select_buffer_end = "shift+end";

    # input_delete_line: 删除整行输入
    input_delete_line = "ctrl+shift+d";

    # input_delete_to_line_end: 删除到行尾
    input_delete_to_line_end = "ctrl+k";

    # input_delete_to_line_start: 删除到行首
    input_delete_to_line_start = "ctrl+u";

    # input_backspace: 退格删除
    input_backspace = "backspace,shift+backspace";

    # input_delete: 前向删除/删除键
    input_delete = "ctrl+d,delete,shift+delete";

    # input_undo: 撤销输入
    input_undo = "ctrl+-,super+z";

    # input_redo: 重做输入
    input_redo = "ctrl+.,super+shift+z";

    # input_word_forward: 向前跳一个单词
    input_word_forward = "alt+f,alt+right,ctrl+right";

    # input_word_backward: 向后跳一个单词
    input_word_backward = "alt+b,alt+left,ctrl+left";

    # input_select_word_forward: 向前选中一个单词
    input_select_word_forward = "alt+shift+f,alt+shift+right";

    # input_select_word_backward: 向后选中一个单词
    input_select_word_backward = "alt+shift+b,alt+shift+left";

    # input_delete_word_forward: 删除后面的一个单词
    input_delete_word_forward = "alt+d,alt+delete,ctrl+delete";

    # input_delete_word_backward: 删除前面的一个单词
    input_delete_word_backward = "ctrl+w,ctrl+backspace,alt+backspace";

    # history_previous: 输入历史上一条
    history_previous = "up";

    # history_next: 输入历史下一条
    history_next = "down";

    # terminal_suspend: 挂起 OpenCode/终端会话
    terminal_suspend = "ctrl+z";

    # terminal_title_toggle: 切换终端标题显示
    terminal_title_toggle = "none";

    # tips_toggle: 切换提示/帮助提示显示
    tips_toggle = "<leader>h";

    # display_thinking: 切换思考块显示; 官方说明 thinking 只影响显示, 不影响模型是否真的启用推理
    display_thinking = "none";
}
